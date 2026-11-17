# Contributing to Ancient Shell

Thanks for your interest in Ancient Shell. Bug reports, ideas, translations, code, and artwork are all welcome. This guide covers how to set up a development copy, the conventions the code follows, and what a pull request needs.

## Reporting bugs

Open an issue with:

- What you did, what you expected, and what happened instead.
- Your Hyprland and Quickshell versions (`hyprctl version`, `qs --version`) and your distribution.
- Your GPU setup, if the bug involves the workspace cube, the Stargate close, or the music effects (hybrid Intel/AMD + NVIDIA laptops behave differently).
- The shell's output. Stop the running shell with `qs -c ancient kill` and start it from a terminal with `qs -c ancient` to see the log.
- The relevant part of `~/.config/ancient-shell/config.json`, if you changed it.

For the updates drawer, also include the output of `quickshell/ancient/scripts/upgrades.py check` and, for a failed upgrade, the end of the upgrade log (`~/upgrade.log` by default).

## Suggesting features

Open an issue describing the idea before writing a large change, so we can agree on the approach first. Features that fit the project keep the Ancient look (charcoal stone, cyan glyph light, amber/bronze accents) and replace or improve something a Hyprland desktop needs.

## Development setup

Install the [dependencies](README.md#dependencies), including the ones listed under "For development" when you work on shaders, translations, or wallpapers. Then:

```sh
git clone <your fork>
cd ancient-shell
./install.sh --now
```

The installer links `quickshell/ancient` into `~/.config/quickshell/ancient` instead of copying it, so the running shell uses your working copy. Quickshell reloads the QML when a file changes, and the shell reloads `config.json` and the `.po` catalogs on its own. Two things need a full restart (`qs -c ancient kill`, then start it again): changes to a shader (`.frag`) and changes to `hypr/init.lua` that affect how the shell is launched.

To remove everything the installer did, run `./install.sh --uninstall`.

## Project layout

See the [Structure](README.md#structure) section of the README. In short: `quickshell/ancient/` is the shell (QML, shaders, Python and Bash helpers), `hypr/` is the Hyprland fragment, `apps/` holds the Qt dark-mode configs, and `wallpapers/` holds the wallpapers together with the scripts that generate them.

## Conventions

### General

- Match the style of the file you are editing. QML, Python, and Bash use 4-space indentation; the Lua files under `hypr/` use tabs.
- Write code, comments, and identifiers in English. Comments should explain why something is done, not restate what the code does.
- Do not hard-code paths or user names. Honor the XDG variables (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `XDG_STATE_HOME`), accept `~/` in configured paths, and read user choices from `config.json`.
- Degrade gracefully. A missing optional tool (a package manager, `power-profiles-daemon`, `cava`, a Bluetooth adapter) must hide or disable the feature that needs it, never break the shell. Keybindings must keep working through Hyprland when the shell is not running.
- Do not enable or start system services on the user's behalf.

### Configuration keys

A new `config.json` key needs a default in the `JsonAdapter` of `quickshell/ancient/services/Config.qml` (path keys are exposed through `path()`, so `~/` expands) and a row in the Configuration table of both READMEs. Existing configs must keep working without the new key.

### Translations

All user-facing text goes through the translation functions:

- QML: `I18n.tr("Text")`, `I18n.tr("Checked at %1", time)`, `I18n.trn("%1 package", "%1 packages", n)`, `I18n.trc("context", "Text")`.
- Python: `_()` (and `ngettext`, `pgettext`) from `scripts/i18n.py`.
- `hypr/hyprlock.conf.in`: the text goes between `{{ }}`.

Put an `i18n:` comment right before a string when translators need context. After adding or changing strings, run:

```sh
quickshell/ancient/i18n/update.sh
```

It regenerates `ancient-shell.pot` and merges it into every `.po` file. If you speak Portuguese, update `pt_BR.po`; otherwise leave the new entries untranslated and mention it in the pull request.

To add a new language, follow [Adding a language](README.md#adding-a-language) in the README. `update.sh --check` must pass for the catalog you submit.

### Shaders

The shell loads the compiled `.qsb` files, not the `.frag` sources. After editing a shader, regenerate its `.qsb` (package `qt6-shadertools`) and commit both files:

```sh
# from the repository root
qsb=/usr/lib/qt6/bin/qsb
dir=quickshell/ancient
$qsb --qt6 -o $dir/wallpaper/shaders/visualizer.frag.qsb $dir/wallpaper/shaders/visualizer.frag
$qsb --qt6 -o $dir/windowfx/shaders/gate.frag.qsb $dir/windowfx/shaders/gate.frag
```

### Wallpapers and artwork

The wallpapers are drawn as vectors by `wallpapers/make-*.py`. Change the script, then regenerate the `.svg` and the `.png` (the usage is in each script's docstring) and commit all three.

Only submit artwork you made yourself or that is under a license compatible with this project. Do not submit screenshots, logos, or other material copied from the Stargate films and series.

### Documentation

The README exists in English (`README.md`) and Brazilian Portuguese (`README.pt_BR.md`), and both describe the same features. When a change affects behavior, shortcuts, configuration, or installation, update both. If you cannot write Portuguese, update the English one and say so in the pull request.

## Testing your change

There is no automated test suite yet, so test by hand on a running Hyprland session:

- Exercise the feature you changed, and anything that shares a service with it.
- Test with more than one monitor if your change involves screens, drawers, the cube, or the wallpaper.
- If you changed `install.sh`, run it on a clean setup, with the flags you touched, and run `./install.sh --uninstall` afterwards to confirm it undoes everything.
- If you changed translatable strings, run `quickshell/ancient/i18n/update.sh --check`.
- If you changed Python code, make sure it still compiles: `python3 -m py_compile quickshell/ancient/scripts/*.py wallpapers/*.py`.
- `qmllint` (QML) and `shellcheck` (Bash) are useful if you have them; please do not introduce new warnings in the files you touch.

## Pull requests

1. Fork the repository and create a branch from the default branch.
2. Keep each pull request focused on one change. Separate refactors from behavior changes.
3. Write commit messages with a short summary line, followed by a body that explains why when it is not obvious.
4. In the pull request description, explain what changed and why, list how you tested it (Hyprland and Quickshell versions included), and add a screenshot or a short recording for any visual change.
5. Link the issue the pull request addresses, if there is one.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE.txt) that covers this project.

The fonts in `quickshell/ancient/assets/fonts/` (Orbitron and Rajdhani) are third-party works under the SIL Open Font License; their license texts are next to them. Any other third-party code or asset you add must carry a license compatible with MIT, and its license text must be included alongside it.

## Code of conduct

Be respectful and constructive. Assume good faith, keep discussions focused on the work, and help newcomers find their way.
