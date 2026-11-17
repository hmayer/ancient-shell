#!/usr/bin/env python3
"""Translations for the shell's scripts and templates, from the gettext .po catalogs in i18n/.

The language comes from the environment the way gettext (and services/I18n.qml) reads it: the
first of LC_ALL, LC_MESSAGES and LANG; in the C or POSIX locale nothing is translated, otherwise
LANGUAGE (a ":" list) comes first. Each language is tried with and without its @modifier and its
region (sr_RS@latin, sr@latin, sr_RS, sr). English ends the list: the sources are English.

As a module:   from i18n import _, ngettext
  _("Docker is stopped")
  ngettext("{n} package", "{n} packages", n).format(n=n)

As a command:
  i18n.py render FILE     FILE with each {{text}} replaced by its translation, on stdout
  i18n.py extract FILE…   the {{text}} of the FILEs as a .pot, on stdout; a comment line that
                          starts with "# i18n:" right before one becomes a note for translators
  i18n.py check PO…       fails if a translation lacks or adds a %1, $NAME or {name} of its original
"""

import gettext
import os
import re
import sys
from pathlib import Path

CATALOGS = Path(__file__).resolve().parent.parent / "i18n"
MARK = re.compile(r"\{\{(.+?)\}\}")


def _bare(locale):
    """"pt_BR.UTF-8@euro" → "pt_BR"."""
    return re.sub(r"[.@].*$", "", locale)


def _is_c(locale):
    return _bare(locale) in ("", "C", "POSIX")


def languages(env=os.environ):
    """The catalogs to try, in order."""
    messages = env.get("LC_ALL") or env.get("LC_MESSAGES") or env.get("LANG") or ""
    if _is_c(messages):
        return []
    out = []
    for loc in env.get("LANGUAGE", "").split(":") + [messages]:
        if _is_c(loc):
            continue
        m = re.match(r"^([^_.@]+)(_[^.@]*)?(?:\.[^@]*)?(@.*)?$", loc)
        if not m:
            continue
        ll, cc, mod = m.group(1), m.group(2) or "", m.group(3) or ""
        for c in (ll + cc + mod, ll + mod, ll + cc, ll):
            if c not in out:
                out.append(c)
        if ll == "en":  # an en_GB.po may exist; anything after English is not wanted
            break
    return out


_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "a": "\a", "b": "\b", "f": "\f", "v": "\v",
            '"': '"', "\\": "\\"}


def _unquote(s):
    return re.sub(r"\\(.)", lambda m: _ESCAPES.get(m.group(1), m.group(1)), s)


def parse(text, plurals=None):
    """A .po file's translated, non-fuzzy entries: {msgid or "ctx\\x04msgid": str or [forms]},
    and its plural rule (a function of n, or None). A dict passed as `plurals` gets the
    msgid_plural of each plural entry."""
    out, header = {}, ""
    e, field = None, None  # the entry being read; what a continuation line extends

    def flush():
        nonlocal e, field, header
        if e and e["id"] is not None:
            if e["id"] == "":
                header = e["strs"].get(0, "")
            elif not e["fuzzy"]:
                key = (e["ctxt"] + "\x04" if e["ctxt"] is not None else "") + e["id"]
                forms = [e["strs"].get(i, "") for i in range(max(e["strs"], default=-1) + 1)]
                if e["plural"] is not None:
                    if forms and all(forms):
                        out[key] = forms
                        if plurals is not None:
                            plurals[key] = e["plural"]
                elif forms and forms[0]:
                    out[key] = forms[0]
        e, field = None, None

    def entry():
        nonlocal e
        if e is None:
            e = {"ctxt": None, "id": None, "plural": None, "strs": {}, "fuzzy": False}
        return e

    for raw in text.split("\n"):
        line = raw.strip()
        if not line:
            flush()
            continue
        if line.startswith("#"):
            if line.startswith("#~"):  # obsolete
                continue
            if e and e["strs"]:        # comments open the next entry
                flush()
            if line.startswith("#,") and re.search(r"\bfuzzy\b", line):
                entry()["fuzzy"] = True
            continue
        m = re.match(r'^(msgctxt|msgid_plural|msgid|msgstr(?:\[(\d+)\])?)\s+"(.*)"$', line)
        if m:
            if m.group(1) in ("msgctxt", "msgid") and e and e["strs"]:
                flush()
            en, val = entry(), _unquote(m.group(3))
            if m.group(1) == "msgctxt":
                en["ctxt"], field = val, "ctxt"
            elif m.group(1) == "msgid":
                en["id"], field = val, "id"
            elif m.group(1) == "msgid_plural":
                en["plural"], field = val, "plural"
            else:
                field = int(m.group(2) or 0)
                en["strs"][field] = val
            continue
        c = re.match(r'^"(.*)"$', line)
        if c and e and field is not None:
            if isinstance(field, int):
                e["strs"][field] += _unquote(c.group(1))
            else:
                e[field] += _unquote(c.group(1))
    flush()

    plural = None
    pm = re.search(r"^Plural-Forms:.*\bplural\s*=\s*([^;\n]+)", header, re.M)
    if pm:
        try:
            plural = gettext.c2py(pm.group(1))
        except (ValueError, AttributeError):
            print(f"i18n: bad Plural-Forms: {pm.group(1)}", file=sys.stderr)
    return out, plural


def load(env=os.environ):
    """The first catalog of languages(env) that exists: (language, messages, plural)."""
    for lang in languages(env):
        path = CATALOGS / f"{lang}.po"
        try:
            text = path.read_text(encoding="utf-8-sig")
        except FileNotFoundError:
            continue
        except (OSError, ValueError) as e:  # unreadable, or not UTF-8: English rather than a crash
            print(f"i18n: {path}: {e}", file=sys.stderr)
            continue
        return (lang, *parse(text))
    return "", {}, None


LANGUAGE, MESSAGES, PLURAL = load()


def _(text):
    t = MESSAGES.get(text)
    return t if isinstance(t, str) else text


def pgettext(context, text):
    t = MESSAGES.get(context + "\x04" + text)
    return t if isinstance(t, str) else text


def ngettext(singular, plural, n):
    forms = MESSAGES.get(singular)
    if isinstance(forms, list) and PLURAL:
        i = PLURAL(n)
        if 0 <= i < len(forms) and forms[i]:
            return forms[i]
    return singular if n == 1 else plural


# What the shell (in "…"), hyprlang (a new line, a block, a comment) or Pango markup would read
# as syntax
TEMPLATE_UNSAFE = re.compile(r'["`\\<>&#{}\x00-\x1f\x7f]')
CONTROL = re.compile(r"[\x00-\x1f\x7f]")


def _placeholders(s):
    return sorted(re.findall(r"%\d+|\$\w*|\{\w*\}", s))


def render(text):
    """Translations in a template must be plain text with the original's $VARIABLES, as they land
    in shell commands, hyprlang and Pango markup; an unsafe one is left in English."""
    def tr(m):
        src, t = m.group(1), _(m.group(1))
        if t != src and (TEMPLATE_UNSAFE.search(t) or _placeholders(t) != _placeholders(src)):
            print(f"i18n: translation of {src!r} left out: it has a line break, \" ` \\ < > & # {{ }}"
                  " or other $ names", file=sys.stderr)
            return src
        return t
    return MARK.sub(tr, text)


def check(paths):
    """Each translation has the placeholders of its original, and no control characters (line
    breaks…) the original lacks. Plural forms need those of both originals, except that the
    form for n = 1 may leave out %1 ("One file")."""
    bad = 0
    for path in paths:
        plurals = {}
        messages, plural = parse(Path(path).read_text(encoding="utf-8-sig"), plurals)
        for key, t in messages.items():
            src = key.split("\x04")[-1]
            if isinstance(t, str):
                checks = [(t, _placeholders(src), set())]
            else:
                want = sorted(set(_placeholders(src)) | set(_placeholders(plurals[key])))
                one = plural(1) if plural else 0
                checks = [(f, want, {"%1"} if i == one else set()) for i, f in enumerate(t)]
            for f, want, optional in checks:
                have = set(_placeholders(f))
                if isinstance(t, str):
                    ok = sorted(_placeholders(f)) == want
                else:
                    ok = have <= set(want) and set(want) - optional <= have
                if not ok:
                    print(f"{path}: {src!r} → {f!r}: placeholders {sorted(have)}, expected {want}",
                          file=sys.stderr)
                    bad += 1
                if set(CONTROL.findall(f)) - set(CONTROL.findall(src)):
                    print(f"{path}: {src!r} → {f!r}: control characters the original lacks",
                          file=sys.stderr)
                    bad += 1
    return 1 if bad else 0


def _po_quote(s):
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t").replace("\n", "\\n")
    return f'"{s}"'


def extract(paths):
    seen = {}  # msgid → [references, notes]
    for path in paths:
        note = []
        for no, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
            c = re.match(r"^\s*#\s*(i18n:.*)$", line)
            if c:
                note.append(c.group(1))
                continue
            for m in MARK.finditer(line):
                refs, notes = seen.setdefault(m.group(1), ([], []))
                refs.append(f"{path}:{no}")
                notes.extend(n for n in note if n not in notes)
            note = []
    out = ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', ""]
    for msgid, (refs, notes) in seen.items():
        out += [f"#. {n}" for n in notes] + [f"#: {' '.join(refs)}",
                                            f"msgid {_po_quote(msgid)}", 'msgstr ""', ""]
    return "\n".join(out)


def main(argv):
    if argv[:1] == ["render"] and len(argv) == 2:
        sys.stdout.write(render(Path(argv[1]).read_text(encoding="utf-8")))
        return 0
    if len(argv) >= 2 and argv[0] == "extract":
        sys.stdout.write(extract(argv[1:]))
        return 0
    if len(argv) >= 2 and argv[0] == "check":
        return check(argv[1:])
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
