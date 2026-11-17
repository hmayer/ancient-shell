pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Translations. The language comes from the locale environment, read the way
// gettext reads it: the first of LC_ALL, LC_MESSAGES and LANG; in the C or
// POSIX locale nothing is translated, otherwise LANGUAGE (a ":" list) comes
// first. Each language is tried with and without its @modifier and region
// (sr_RS@latin, sr@latin, sr_RS, sr), and English ends the list, as the
// sources are English. The first catalog found is used. Catalogs are gettext
// .po files in i18n/, kept in step with the sources by i18n/update.sh.
//
//     I18n.tr("Lock")                                → "Bloquear"
//     I18n.tr("Checked at %1", time)                 → "Verificado às 10:42"
//     I18n.trn("%1 package", "%1 packages", n)       → "3 pacotes"
//     I18n.trc("weekday", "Sun")                     (msgctxt "weekday")
Singleton {
    id: root

    function _env(name) {
        return Quickshell.env(name) || "";
    }
    // "pt_BR.UTF-8@euro" → "pt_BR"
    function _bare(locale) {
        return String(locale).replace(/[.@].*$/, "");
    }
    function _isC(locale) {
        const b = _bare(locale);
        return b === "" || b === "C" || b === "POSIX";
    }

    readonly property string messagesLocale: _env("LC_ALL") || _env("LC_MESSAGES") || _env("LANG")
    // Catalogs to try, in order
    readonly property var languages: {
        if (_isC(messagesLocale)) return [];
        const out = [];
        for (const l of _env("LANGUAGE").split(":").concat([messagesLocale])) {
            if (_isC(l)) continue;
            // language, _REGION, .encoding, @modifier
            const m = l.match(/^([^_.@]+)(_[^.@]*)?(?:\.[^@]*)?(@.*)?$/);
            if (!m) continue;
            const ll = m[1], cc = m[2] ?? "", mod = m[3] ?? "";
            for (const c of [ll + cc + mod, ll + mod, ll + cc, ll])
                if (!out.includes(c)) out.push(c);
            // An en_GB.po may exist; anything after English is not wanted
            if (ll === "en") break;
        }
        return out;
    }
    // Locale for dates and numbers (Config.locale uses it unless set)
    readonly property string timeLocale: {
        const l = _env("LC_ALL") || _env("LC_TIME") || _env("LANG");
        const b = _bare(l) || "C";
        // Qt ignores glibc's script modifiers: sr_RS@latin → sr_Latn_RS
        const script = { latin: "Latn", cyrillic: "Cyrl" }[(l.match(/@(.*)$/) ?? [])[1]];
        return script ? b.replace(/^([^_]+)/, "$1_" + script) : b;
    }

    // The first catalog that exists. Reading a file's text blocks until it is
    // loaded, so the windows start translated.
    readonly property var _found: {
        for (let i = 0; i < files.count; i++) {
            const t = files.objectAt(i)?.text() ?? "";
            if (t !== "") return { text: t, language: languages[i] };
        }
        return { text: "", language: "" };
    }
    readonly property var _catalog: _parse(_found.text)
    // The catalog in use ("" = none, the English of the sources)
    readonly property string language: _found.language
    // Its language code ("pt"); "en" without a catalog
    readonly property string lang2: language !== "" ? language.split(/[_@]/)[0] : "en"
    // msgid (with "context\u0004" in front when it has one) → translation,
    // or the list of plural forms
    readonly property var messages: _catalog.messages
    readonly property var _plural: _catalog.plural

    function tr(text, ...args) {
        const t = messages[text];
        return _fmt(typeof t === "string" ? t : text, args);
    }

    function trc(context, text, ...args) {
        const t = messages[context + "\u0004" + text];
        return _fmt(typeof t === "string" ? t : text, args);
    }

    // %1 is n
    function trn(singular, plural, n, ...args) {
        const forms = messages[singular];
        let s = "";
        if (Array.isArray(forms) && _plural) s = forms[_plural(n)] ?? "";
        if (s === "") s = n === 1 ? singular : plural;
        return _fmt(s, [n].concat(args));
    }

    function _fmt(s, args) {
        return s.replace(/%(\d+)/g, (m, i) => i >= 1 && i <= args.length ? String(args[i - 1]) : m);
    }

    function _unquote(s) {
        const esc = { n: "\n", t: "\t", r: "\r", a: "\x07", b: "\b", f: "\f", v: "\v", "\"": "\"", "\\": "\\" };
        return s.replace(/\\(.)/g, (m, c) => esc[c] ?? c);
    }

    // A gettext .po file: translated, non-fuzzy entries only
    function _parse(src) {
        const out = {};
        let header = "";
        let e = null;      // entry being read
        let field = null;  // what a continuation line extends: "ctxt", "id", "plural" or a msgstr index

        function flush() {
            if (e && e.id !== null) {
                if (e.id === "") {
                    header = e.strs[0] ?? "";
                } else if (!e.fuzzy) {
                    const key = (e.ctxt !== null ? e.ctxt + "\u0004" : "") + e.id;
                    if (e.plural !== null) {
                        if (e.strs.length > 0 && e.strs.every(s => s)) out[key] = e.strs.slice();
                    } else if (e.strs[0]) {
                        out[key] = e.strs[0];
                    }
                }
            }
            e = null;
            field = null;
        }
        function entry() {
            if (!e) e = { ctxt: null, id: null, plural: null, strs: [], fuzzy: false };
            return e;
        }

        for (const raw of src.split("\n")) {
            const line = raw.trim();
            if (line === "") {
                flush();
                continue;
            }
            if (line.startsWith("#")) {
                if (line.startsWith("#~")) continue;          // obsolete
                if (e && e.strs.length > 0) flush();          // comments open the next entry
                if (line.startsWith("#,") && /\bfuzzy\b/.test(line)) entry().fuzzy = true;
                continue;
            }
            const m = line.match(/^(msgctxt|msgid_plural|msgid|msgstr(?:\[(\d+)\])?)\s+"(.*)"$/);
            if (m) {
                if ((m[1] === "msgctxt" || m[1] === "msgid") && e && e.strs.length > 0) flush();
                const en = entry();
                const val = _unquote(m[3]);
                if (m[1] === "msgctxt") { en.ctxt = val; field = "ctxt"; }
                else if (m[1] === "msgid") { en.id = val; field = "id"; }
                else if (m[1] === "msgid_plural") { en.plural = val; field = "plural"; }
                else { field = m[2] !== undefined ? Number(m[2]) : 0; en.strs[field] = val; }
                continue;
            }
            const c = line.match(/^"(.*)"$/);
            if (c && e && field !== null) {
                if (typeof field === "number") e.strs[field] += _unquote(c[1]);
                else e[field] += _unquote(c[1]);
            }
        }
        flush();

        // Plural-Forms: nplurals=2; plural=(n > 1);  (a C expression of n)
        let plural = null;
        const pm = header.match(/^Plural-Forms:.*\bplural\s*=\s*([^;\n]+)/m);
        if (pm && /^[n0-9\s()?:<>=!&|%+*\/-]+$/.test(pm[1])) {
            try {
                const f = new Function("n", "return Number(" + pm[1] + ");");
                f(1);
                plural = f;
            } catch (err) {
                console.warn("i18n: bad Plural-Forms:", pm[1]);
            }
        }
        return { messages: out, plural };
    }

    // One file per language to try; missing ones are simply empty
    Instantiator {
        id: files
        model: root.languages
        FileView {
            required property string modelData
            path: Quickshell.shellPath("i18n/" + modelData + ".po")
            blockLoading: true
            printErrors: false
            watchChanges: true
            onFileChanged: reload()
        }
    }
}
