#!/usr/bin/env python3
"""Pending package upgrades for the bar, and the topgrade run that applies them.

  upgrades.py check [ID...]   One JSON line per package manager, as each check ends:
                                {"id": "node", "count": 3}
                                {"id": "docker", "note": "Docker is stopped"}   (not checked)
                                {"id": "uv", "error": "..."}                (check failed)
                                {"id": "cargo", "missing": true}            (not installed)
  upgrades.py run ID...       Upgrades those managers with topgrade, in a detached worker
                              that outlives the shell, and follows its output. The output
                              is appended to the log; the exit code is topgrade's.
  upgrades.py follow          Follows a run that is still going (exit 100 if there is none).

Each count is what topgrade's step would change, so a run brings it to zero.

The shell passes its config through the environment ("~" is expanded):
  ANCIENT_NODE_BIN     bin directory of the Node whose global npm packages count
                       (`upgradesNodeBin`); unset or empty: the npm in PATH
  ANCIENT_UPGRADE_LOG  file the runs' output is appended to (`upgradesLog`),
                       default ~/upgrade.log
  ANCIENT_EXTRA_PATH   directories put before PATH, ":"-separated (`upgradesPath`),
                       default ~/.cargo/bin:~/.local/bin
Tools found in their own default places honour their own overrides: ZSH,
VSCODE_EXTENSIONS and CLAUDE_CONFIG_DIR.
"""

import concurrent.futures
import fcntl
import json
import os
import platform
import posixpath
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

from i18n import _  # this directory's i18n.py

HOME = Path.home()
NODE_BIN = os.path.expanduser(os.environ.get("ANCIENT_NODE_BIN", ""))
LOG = Path(os.path.expanduser(os.environ.get("ANCIENT_UPGRADE_LOG") or "~/upgrade.log"))
EXTRA_PATH = [os.path.expanduser(d) for d in
              os.environ.get("ANCIENT_EXTRA_PATH", "~/.cargo/bin:~/.local/bin").split(os.pathsep) if d]
STATE = Path(os.environ.get("XDG_CACHE_HOME") or HOME / ".cache") / "ancient-shell" / "upgrade.json"
LOCK = STATE.with_suffix(".lock")   # held by the worker for as long as it lives
NOTHING_TO_FOLLOW = 100

# The shell runs with the session's PATH, which often lacks nvm, cargo and ~/.local/bin
os.environ["PATH"] = os.pathsep.join(
    ([NODE_BIN] if NODE_BIN else []) + EXTRA_PATH + [os.environ.get("PATH", "")])
os.environ.setdefault("ZSH", str(HOME / ".oh-my-zsh"))

# Checks parse English output
CHECK_ENV = dict(os.environ, LC_ALL="C.UTF-8", LANG="C.UTF-8")

# Manager id → topgrade steps
STEPS = {
    "system": ["system"],
    "omz": ["shell"],
    "cargo": ["cargo"],
    "vscode": ["vscode"],
    "nvim": ["vim"],
    "node": ["node"],
    "docker": ["containers"],
    "composer": ["composer"],
    "github": ["github_cli_extensions", "github_cli_skills"],
    "claude": ["claude_code", "claude_code_plugins"],
    "uv": ["uv"],
}


class Missing(Exception):
    """The package manager is not installed."""


class Note(Exception):
    """The check was skipped, for the reason given."""


def need(name):
    path = shutil.which(name)
    if not path:
        raise Missing(name)
    return path


def sh(*cmd, ok=(0,), timeout=180):
    """Run a command; with `ok`, an exit code outside it fails the check."""
    try:
        p = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, timeout=timeout,
                           env=CHECK_ENV, stdin=subprocess.DEVNULL, cwd=HOME)
    except FileNotFoundError:
        raise Missing(cmd[0])
    except subprocess.TimeoutExpired:
        raise RuntimeError(_("{command}: timed out").format(command=Path(str(cmd[0])).name))
    if ok is not None and p.returncode not in ok:
        lines = (p.stderr.strip() or p.stdout.strip()).splitlines()
        raise RuntimeError(lines[-1] if lines else _("{command} exited with {code}").format(
            command=Path(str(cmd[0])).name, code=p.returncode))
    return p


def http(url, data=None, headers=None, method=None, timeout=15):
    req = urllib.request.Request(url, data=data, headers=headers or {}, method=method)
    return urllib.request.urlopen(req, timeout=timeout)


def vkey(version):
    """Sortable key of a version string: its numbers, before any pre-release suffix."""
    return tuple(int(n) for n in re.findall(r"\d+", str(version).lstrip("v").split("-")[0].split("+")[0]))


# ── Checks ────────────────────────────────────────────────────────────

def check_system():
    """Repo packages from a scratch copy of the sync databases (no root, no lock), AUR from its RPC."""
    need("yay")
    if not shutil.which("checkupdates"):
        raise RuntimeError(_("checkupdates not found (pacman-contrib)"))
    line = re.compile(r"^\S+ \S+ -> \S+")
    repo = sh("checkupdates", ok=(0, 2)).stdout  # 2: nothing to update
    aur = sh("yay", "-Qua", ok=(0, 1))           # 1: nothing to update, or a failure
    if aur.returncode == 1 and "error" in aur.stderr.lower():
        raise RuntimeError(aur.stderr.strip().splitlines()[-1])
    # IgnorePkg packages are listed too, marked [ignored]; pacman never upgrades them
    return sum(1 for text in (repo, aur.stdout) for l in text.splitlines()
               if line.match(l) and not l.rstrip().endswith("[ignored]"))


def check_omz():
    """topgrade runs Oh My Zsh's own upgrade.sh, which updates the framework, not the custom plugins."""
    need("zsh")
    zsh = Path(os.environ["ZSH"])
    if not (zsh / ".git").exists():
        raise Missing("oh-my-zsh")

    def config(key, default):
        p = sh("git", "-C", zsh, "config", "--get", key, ok=None)
        return p.stdout.strip() or default

    remote, branch = config("oh-my-zsh.remote", "origin"), config("oh-my-zsh.branch", "master")
    sh("git", "-C", zsh, "fetch", "--quiet", remote, branch, timeout=60)
    behind = int(sh("git", "-C", zsh, "rev-list", "--count", f"HEAD..{remote}/{branch}").stdout)
    return 1 if behind else 0


def check_cargo():
    need("cargo")
    need("cargo-install-update")  # topgrade's cargo step needs it as well
    out = sh("cargo", "install-update", "--list", "--git").stdout
    return sum(1 for l in out.splitlines() if re.match(r"^\S+\s+\S+\s+\S+\s+Yes\s*$", l))


def check_vscode():
    """Installed extensions against the Marketplace's latest version for this VS Code and platform."""
    need("code")
    listing = Path(os.path.expanduser(os.environ.get("VSCODE_EXTENSIONS") or "~/.vscode/extensions")) \
        / "extensions.json"
    if not listing.exists():
        return 0
    installed = [e for e in json.loads(listing.read_text()) if not (e.get("metadata") or {}).get("pinned")]
    if not installed:
        return 0
    code = vkey(sh("code", "--version").stdout.split()[0])
    arch = {"x86_64": "x64", "aarch64": "arm64", "armv7l": "armhf"}.get(platform.machine(), platform.machine())
    platforms = {None, "undefined", "universal", f"linux-{arch}"}

    body = {
        "filters": [{
            "criteria": [{"filterType": 8, "value": "Microsoft.VisualStudio.Code"},
                         {"filterType": 12, "value": "4096"}]
                        + [{"filterType": 7, "value": e["identifier"]["id"]} for e in installed],
            "pageNumber": 1, "pageSize": len(installed), "sortBy": 0, "sortOrder": 0,
        }],
        # versions + their properties, only the latest stable and pre-release of each
        "flags": 0x1 | 0x10 | 0x10000,
    }
    with http("https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery",
              data=json.dumps(body).encode(), method="POST",
              headers={"Content-Type": "application/json",
                       "Accept": "application/json;api-version=3.0-preview.1"}) as r:
        found = json.load(r)["results"][0]["extensions"]
    versions = {f'{x["publisher"]["publisherName"]}.{x["extensionName"]}'.lower(): x.get("versions", [])
                for x in found}

    count = 0
    for ext in installed:
        meta = ext.get("metadata") or {}
        prerelease = meta.get("preRelease") or meta.get("isPreReleaseVersion")
        best = None
        for v in versions.get(ext["identifier"]["id"].lower(), []):
            props = {p["key"]: p["value"] for p in v.get("properties", [])}
            if v.get("targetPlatform") not in platforms:
                continue
            if props.get("Microsoft.VisualStudio.Code.PreRelease") == "true" and not prerelease:
                continue
            engine = props.get("Microsoft.VisualStudio.Code.Engine", "*")
            if engine.strip() not in ("*", "") and vkey(engine) > code:
                continue
            if best is None or vkey(v["version"]) > vkey(best):
                best = v["version"]
        if best and vkey(best) > vkey(ext["version"]):
            count += 1
    return count


LAZY_CHECK = """
local ok, res = pcall(function()
  require("lazy.manage").check({ show = false, wait = true })
  local names = {}
  for _, p in pairs(require("lazy.core.config").plugins) do
    if p._.updates then names[#names + 1] = p.name end
  end
  return names
end)
io.stdout:write("\\nANCIENT-LAZY " .. vim.json.encode(ok and { updates = res } or { error = tostring(res) }) .. "\\n")
vim.cmd("qa!")
"""


def check_nvim():
    """lazy.nvim's own check (git fetch of every plugin), run in a headless Neovim with the user's config."""
    need("nvim")
    out = sh("nvim", "--headless", "-c", "lua " + LAZY_CHECK.replace("\n", " "), ok=None, timeout=300).stdout
    m = re.search(r"^ANCIENT-LAZY (.*)$", out, re.M)
    if not m:
        raise RuntimeError(_("lazy.nvim did not answer"))
    res = json.loads(m.group(1))
    if "error" in res:
        raise RuntimeError(res["error"].splitlines()[0])
    return len(res["updates"])


def check_node():
    """`npm update -g` moves each global package to its "wanted" version."""
    npm = need("npm")  # NODE_BIN comes first in PATH
    out = sh(npm, "outdated", "-g", "--json", ok=(0, 1)).stdout  # 1: something is outdated
    data = json.loads(out or "{}")
    if "error" in data:
        raise RuntimeError(data["error"].get("summary") or _("npm outdated failed"))
    return sum(1 for v in data.values() if v.get("current") != v.get("wanted"))


MANIFEST_TYPES = ", ".join([
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.v2+json",
])


def remote_digest(ref):
    """Digest the tag points to in its registry, anonymously, or None (local build, private, offline).
    HEAD requests do not count against Docker Hub's pull rate limit."""
    name, tag = ref.rsplit(":", 1)
    first, _, rest = name.partition("/")
    if rest and ("." in first or ":" in first or first == "localhost"):
        registry, repo = first, rest
    else:
        registry, repo = "registry-1.docker.io", name if "/" in name else "library/" + name
    url = f"https://{registry}/v2/{repo}/manifests/{tag}"

    def head(token=None):
        headers = {"Accept": MANIFEST_TYPES}
        if token:
            headers["Authorization"] = "Bearer " + token
        try:
            with http(url, headers=headers, method="HEAD", timeout=10) as r:
                return r.status, r.headers
        except urllib.error.HTTPError as e:
            return e.code, e.headers

    try:
        status, headers = head()
        if status == 401:
            challenge = headers.get("WWW-Authenticate", "")
            params = dict(re.findall(r'(\w+)="([^"]*)"', challenge))
            if not challenge.lower().startswith("bearer") or "realm" not in params:
                return None
            query = urllib.parse.urlencode({k: v for k, v in params.items() if k in ("service", "scope")})
            with http(params["realm"] + "?" + query, timeout=10) as r:
                grant = json.load(r)
            status, headers = head(grant.get("token") or grant.get("access_token"))
        return headers.get("Docker-Content-Digest") if status == 200 else None
    except (OSError, ValueError):
        return None


def check_docker():
    """Tagged images whose tag now points elsewhere in the registry; images built here have no
    registry behind them and topgrade skips them too."""
    need("docker")
    # Do not wake a socket-activated daemon just to look
    if shutil.which("systemctl"):
        if sh("systemctl", "is-active", "--quiet", "docker.service", ok=None).returncode != 0:
            raise Note(_("Docker is stopped"))
    out = sh("docker", "image", "ls", "--format", "{{.Repository}}:{{.Tag}}", timeout=30).stdout
    refs = sorted({r for r in out.split() if "<none>" not in r})
    if not refs:
        return 0
    images = json.loads(sh("docker", "image", "inspect", *refs, timeout=30).stdout)
    local = {ref: {d.split("@", 1)[1] for d in (img.get("RepoDigests") or []) if "@" in d}
             for ref, img in zip(refs, images)}
    with concurrent.futures.ThreadPoolExecutor(8) as pool:
        remote = dict(zip(refs, pool.map(remote_digest, refs)))
    return sum(1 for ref in refs if remote[ref] and remote[ref] not in local[ref])


def check_composer():
    """What `composer global update` would do, from its dry run."""
    need("composer")
    p = sh("composer", "global", "update", "--dry-run", "--no-interaction", "--no-ansi")
    m = re.search(r"operations: (\d+) installs?, (\d+) updates?, (\d+) removals?", p.stdout + p.stderr)
    return sum(int(n) for n in m.groups()) if m else 0


def check_github():
    need("gh")
    ext = sh("gh", "extension", "upgrade", "--all", "--dry-run", ok=None)
    count = (ext.stdout + ext.stderr).count("would have upgraded")
    # `gh skill` is a preview command, missing from older gh releases
    skills = sh("gh", "skill", "update", "--all", "--dry-run", ok=None)
    m = re.search(r"(\d+) update\(s\) available", skills.stdout + skills.stderr)
    return count + (int(m.group(1)) if m else 0)


def claude_plugin_updates(claude):
    """Installed plugins whose marketplace now lists another version. Git marketplaces are fetched
    (not pulled); the others are refreshed by Claude Code itself."""
    plugins = json.loads(sh(claude, "plugin", "list", "--json", timeout=60).stdout)
    markets = {m["name"]: Path(m["installLocation"])
               for m in json.loads(sh(claude, "plugin", "marketplace", "list", "--json", timeout=60).stdout)
               if m.get("installLocation")}
    readers = {}

    def reader(market):
        where = markets[market]
        if (where / ".git").exists():
            sh("git", "-C", where, "fetch", "--quiet", timeout=60)

            def read(rel):
                p = sh("git", "-C", where, "show", f"@{{u}}:{rel}", ok=None)
                return p.stdout if p.returncode == 0 else None
        else:
            def read(rel):
                f = where / rel
                return f.read_text() if f.exists() else None
        return read

    count = 0
    for plugin in plugins:
        name, _, market = plugin["id"].rpartition("@")
        if market not in markets or plugin.get("version") in (None, "", "unknown"):
            continue
        if market not in readers:
            readers[market] = reader(market)
        read = readers[market]
        listing = json.loads(read(".claude-plugin/marketplace.json") or "{}")
        entry = next((e for e in listing.get("plugins", []) if e.get("name") == name), None)
        if not entry:
            continue
        version = None
        source = entry.get("source")
        if isinstance(source, str) and source.startswith("./"):
            manifest = read(posixpath.normpath(posixpath.join(source, ".claude-plugin/plugin.json")))
            if manifest:
                version = json.loads(manifest).get("version")
        version = version or entry.get("version")
        if version and version != plugin["version"]:
            count += 1
    return count


def check_claude():
    """Claude Code against its release channel, plus its plugins."""
    claude = need("claude")  # the native installer's ~/.local/bin is in EXTRA_PATH by default
    installed = sh(claude, "--version", timeout=30).stdout.split()[0]
    channel = "latest"
    settings = Path(os.path.expanduser(os.environ.get("CLAUDE_CONFIG_DIR") or "~/.claude")) / "settings.json"
    if settings.exists():
        try:
            channel = json.loads(settings.read_text()).get("autoUpdatesChannel") or channel
        except ValueError:
            pass
    with http(f"https://downloads.claude.ai/claude-code-releases/{channel}") as r:
        latest = r.read().decode().strip()
    return (1 if vkey(latest) > vkey(installed) else 0) + claude_plugin_updates(claude)


def check_uv():
    """uv tools, uv itself when it can update itself, and uv-managed Pythons with a newer patch."""
    uv = need("uv")
    count = sum(1 for l in sh(uv, "tool", "list", "--outdated", timeout=60).stdout.splitlines()
                if "[latest:" in l)
    me = sh(uv, "self", "update", "--dry-run", ok=None, timeout=60)
    if me.returncode == 0 and "would update" in (me.stdout + me.stderr).lower():
        count += 1
    pythons = json.loads(sh(uv, "python", "list", "--managed-python", "--output-format", "json",
                            ok=None).stdout or "[]")

    def series(p):
        return (p.get("implementation"), p["version_parts"]["major"], p["version_parts"]["minor"],
                p.get("variant"), p.get("arch"))

    installed = {}
    for p in pythons:
        if p.get("path"):
            installed[series(p)] = max(installed.get(series(p), -1), p["version_parts"]["patch"])
    newer = {series(p) for p in pythons if not p.get("path") and series(p) in installed
             and p["version_parts"]["patch"] > installed[series(p)]}
    return count + len(newer)


CHECKS = {
    "system": check_system,
    "omz": check_omz,
    "cargo": check_cargo,
    "vscode": check_vscode,
    "nvim": check_nvim,
    "node": check_node,
    "docker": check_docker,
    "composer": check_composer,
    "github": check_github,
    "claude": check_claude,
    "uv": check_uv,
}


def run_check(mid):
    try:
        return {"id": mid, "count": CHECKS[mid]()}
    except Missing:
        return {"id": mid, "missing": True}
    except Note as e:
        return {"id": mid, "note": str(e)}
    except Exception as e:  # one failed check must not take the others down
        return {"id": mid, "error": str(e) or type(e).__name__}


def cmd_check(ids):
    ids = [i for i in ids if i in CHECKS] or list(CHECKS)
    with concurrent.futures.ThreadPoolExecutor(len(ids)) as pool:
        for done in concurrent.futures.as_completed([pool.submit(run_check, i) for i in ids]):
            print(json.dumps(done.result()), flush=True)
    return 0


# ── Upgrade run ───────────────────────────────────────────────────────

ANSI = re.compile(rb"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b[()][0-9A-Za-z]")


def clean(raw):
    """One output line without colours, keeping only the last state of a line redrawn with \\r."""
    parts = [p for p in ANSI.sub(b"", raw.rstrip(b"\n")).split(b"\r") if p.strip()]
    return (parts[-1].rstrip() if parts else b"") + b"\n"


def read_state():
    try:
        return json.loads(STATE.read_text())
    except (OSError, ValueError):
        return {}


def write_state(state):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    tmp.replace(STATE)


def run_going():
    """Whether a worker holds the run lock (released when it exits, however it exits)."""
    try:
        fd = os.open(LOCK, os.O_RDONLY)
    except OSError:
        return False
    try:
        fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)
        return False
    except BlockingIOError:
        return True
    finally:
        os.close(fd)


def current_run():
    """State of the run going on, or None."""
    while run_going():
        state = read_state()
        if state.get("pid") and "exit" not in state and Path(f"/proc/{state['pid']}").exists():
            return state
        time.sleep(0.05)  # its worker is about to record it
    return None


def cmd_worker(ids):
    """Runs topgrade in its own session, so that a restart of the shell cannot cut a pacman
    transaction short, and writes its output to the log."""
    STATE.parent.mkdir(parents=True, exist_ok=True)
    lock = open(LOCK, "a")  # kept open, and so locked, until the worker exits
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return 75  # another run started at the same moment
    steps = [s for i in ids for s in STEPS[i]]
    cmd = ["topgrade", "--no-tmux", "--no-self-update", "--no-ask-retry", "--yes", "--only", *steps]
    # No shutdown or suspend while packages are being replaced
    if shutil.which("systemd-inhibit"):
        cmd = ["systemd-inhibit", "--what=shutdown:sleep", "--mode=block",
               "--who=Ancient Shell", "--why=" + _("Upgrading packages"), *cmd]
    # After a major update, topgrade asks on stdin to confirm its breaking changes
    env = dict(os.environ, TOPGRADE_SKIP_BRKC_NOTIFY="true")

    with open(LOG, "ab", buffering=0) as log:
        state = {"pid": os.getpid(), "offset": log.tell(), "ids": ids, "log": str(LOG)}
        write_state(state)

        def put(text):
            # Keep draining topgrade's output even if the log cannot be written (full disk):
            # with nobody reading its pipe, pacman would die of SIGPIPE mid-transaction
            try:
                log.write(text)
            except OSError:
                pass

        def stamp():
            return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        put(f"━━━━ {stamp()} · upgrade: {' '.join(ids)} ━━━━\n$ {' '.join(cmd)}\n".encode())
        try:
            proc = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, cwd=HOME, env=env)
        except OSError as e:
            put(f"{e}\n".encode())
            code = 127
        else:
            for raw in iter(proc.stdout.readline, b""):
                put(clean(raw))
            code = proc.wait()
        footer = _("end, exit code {code}").format(code=code)
        put(f"━━━━ {stamp()} · {footer} ━━━━\n\n".encode())
    write_state(dict(state, exit=code))
    return code


def follow(state, child=None):
    """Copies the run's output from the log to stdout until the worker is gone."""
    def alive():
        return child.poll() is None if child else run_going()

    out = sys.stdout.buffer
    # The log the run writes to, which may not be the one configured now
    with open(state.get("log") or LOG, "rb") as log:
        log.seek(state["offset"])
        while True:
            chunk = log.read(65536)
            if chunk:
                try:
                    out.write(chunk)
                    out.flush()
                except BrokenPipeError:
                    return 1  # the shell went away; the worker carries on
                continue
            if not alive():
                rest = log.read()
                if rest:
                    out.write(rest)
                    out.flush()
                break
            time.sleep(0.25)
    final = read_state()
    return final.get("exit", 1) if final.get("pid") == state["pid"] else 1


def cmd_run(ids):
    if state := current_run():
        return follow(state)  # one run at a time: show the one going on
    ids = [i for i in dict.fromkeys(ids) if i in STEPS]
    if not ids:
        print(_("nothing to upgrade"), file=sys.stderr)
        return 2
    LOG.parent.mkdir(parents=True, exist_ok=True)
    LOG.touch()
    child = subprocess.Popen([sys.executable, os.path.abspath(__file__), "worker", *ids],
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, cwd=HOME, start_new_session=True)
    # The worker takes the lock and records where its output starts in the log
    while (state := read_state()).get("pid") != child.pid:
        if child.poll() is not None:
            if state := current_run():  # it lost the lock to a run started at the same moment
                return follow(state)
            print(_("the upgrade did not start"), file=sys.stderr)
            return 1
        time.sleep(0.05)
    return follow(state, child)


def cmd_follow():
    state = current_run()
    return follow(state) if state else NOTHING_TO_FOLLOW


def main(argv):
    if not argv:
        print(__doc__, file=sys.stderr)
        return 2
    cmd, args = argv[0], argv[1:]
    if cmd == "check":
        return cmd_check(args)
    if cmd == "run":
        return cmd_run(args)
    if cmd == "follow":
        return cmd_follow()
    if cmd == "worker":
        return cmd_worker(args)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
