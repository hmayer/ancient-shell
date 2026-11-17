#!/usr/bin/env bash
# Keeps the translation catalogs in step with the sources: extracts the translatable texts
# into ancient-shell.pot and merges it into every <language>.po here. Needs GNU gettext.
#
#   quickshell/ancient/i18n/update.sh           update the template and the catalogs
#   quickshell/ancient/i18n/update.sh --check   …and fail if the template was out of date or a
#                                                catalog has untranslated or fuzzy messages
#
# Either way it fails when a translation lacks or adds a placeholder (%1, $NAME, {name}).
#
# Translatable texts: I18n.tr / trn / trc in the QML, _ / ngettext / pgettext in scripts/*.py,
# {{text}} in hypr/hyprlock.conf.in. A comment starting with "i18n:" right before one becomes a
# note for translators.
set -euo pipefail

check=0
case "${1:-}" in
    --check) check=1 ;;
    "") ;;
    *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$dir/../../.."   # the repository, so the references read quickshell/ancient/…
qs=quickshell/ancient
pot="$qs/i18n/ancient-shell.pot"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

common=(--from-code=UTF-8 --add-comments=i18n: --sort-by-file --package-name=ancient-shell --no-wrap)
# xgettext, without its advice to set --msgid-bugs-address (there is no bug address)
xg() {
    local err
    err="$(xgettext "${common[@]}" "$@" 2>&1)" || { printf '%s\n' "$err" >&2; return 1; }
    printf '%s\n' "$err" | awk '/msgid-bugs-address was not specified/ { skip = 4 } skip { skip--; next } NF' >&2
}
mapfile -t qml < <(find "$qs" -name '*.qml' -not -path "$qs/i18n/*" | sort)
xg -L JavaScript -k -ktr -ktrn:1,2 -ktrc:1c,2 -o "$tmp/new.pot" "${qml[@]}"
xg -L Python -k -k_ -kngettext:1,2 -kpgettext:1c,2 -j -o "$tmp/new.pot" \
    "$qs"/scripts/*.py
python3 "$qs/scripts/i18n.py" extract hypr/hyprlock.conf.in > "$tmp/lock.pot"
xg -L PO -j -o "$tmp/new.pot" "$tmp/lock.pot"
sed -i 's/charset=CHARSET/charset=UTF-8/' "$tmp/new.pot"

status=0
# Only the creation date changed: keep the old file
if [ -f "$pot" ] && cmp -s <(grep -v '^"POT-Creation-Date:' "$tmp/new.pot") \
                         <(grep -v '^"POT-Creation-Date:' "$pot"); then
    echo "$pot: unchanged"
else
    mv "$tmp/new.pot" "$pot"
    echo "$pot: updated"
    [ "$check" = 0 ] || status=1
fi

for po in "$qs"/i18n/*.po; do
    [ -e "$po" ] || continue
    msgmerge --quiet --update --backup=none --no-wrap "$po" "$pot"
    stats="$(msgfmt --check --statistics -o /dev/null "$po" 2>&1)" || status=1
    echo "$po: $stats"
    python3 "$qs/scripts/i18n.py" check "$po" || status=1
    if [ "$check" = 1 ] && grep -qE 'fuzzy|untranslated' <<<"$stats"; then
        status=1
    fi
done
exit "$status"
