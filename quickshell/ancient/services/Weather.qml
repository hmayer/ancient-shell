pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Weather for a city the user picks (never guessed from the IP), from
// Open-Meteo: free, no account. Current conditions and the next 6 hours,
// refreshed every 15 minutes while the desktop widget is shown.
Singleton {
    id: root

    // Where the widget lives and what it shows, kept between sessions
    readonly property alias saved: st
    readonly property bool hasPlace: st.name !== ""
    readonly property string placeLabel: st.name + (st.region ? " · " + st.region : "")
    // The screen the widget lives on: the saved one while it is connected
    readonly property string screenName: Quickshell.screens.some(s => s.name === st.screen)
        ? st.screen : (Quickshell.screens[0]?.name ?? "")

    property var current: null     // { temp, feels, code, kind, day, windSpeed, windDir }
    property var hours: []          // the next 6: { time, temp, feels, code, kind, day, rain, windSpeed, windDir }
    property string status: ""      // "", "loading", "ok", "error"
    property date updated: new Date(0)

    property bool expanded: false   // the widget shows the next hours

    property var results: []        // city search: { name, region, country, lat, lon }
    property string searchStatus: "" // "", "loading", "none", "error"

    // `pick`: take the first match straight away (IPC)
    property bool _pick: false
    function search(text, pick) {
        text = text.trim();
        if (text === "") return;
        _pick = pick === true;
        searchStatus = "loading";
        results = [];
        finder.command = ["curl", "-sf", "-m", "10", "-G", "https://geocoding-api.open-meteo.com/v1/search",
            "--data-urlencode", "name=" + text, "-d", "count=6", "-d", "language=pt"];
        finder.running = true;
    }

    function choose(place) {
        st.name = place.name;
        st.region = place.region;
        st.country = place.country;
        st.lat = place.lat;
        st.lon = place.lon;
        results = [];
        searchStatus = "";
        current = null;
        hours = [];
        refresh();
    }

    function toggle() {
        st.shown = !st.shown;
        if (st.shown) refresh();
    }

    // Bring the widget to `screenName`, at its default place there
    function moveTo(screenName) {
        st.screen = screenName;
        st.x = -1;
        st.y = -1;
    }

    function refresh() {
        if (!hasPlace || !st.shown) return;
        status = "loading";
        fetcher.command = ["curl", "-sf", "-m", "15", "-G", "https://api.open-meteo.com/v1/forecast",
            "-d", "latitude=" + st.lat, "-d", "longitude=" + st.lon,
            "-d", "timezone=auto", "-d", "forecast_hours=7",
            "-d", "current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,is_day",
            "-d", "hourly=temperature_2m,apparent_temperature,weather_code,precipitation_probability,wind_speed_10m,wind_direction_10m,is_day"];
        fetcher.running = true;
    }

    // ── What the WMO weather codes mean ──────────────
    // kind drives the widget's animation
    function kind(code) {
        if (code === 0 || code === 1) return "clear";
        if (code === 2) return "partly";
        if (code === 3) return "cloudy";
        if (code === 45 || code === 48) return "fog";
        if (code >= 51 && code <= 57) return "drizzle";
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return "rain";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow";
        if (code >= 95) return "storm";
        return "cloudy";
    }

    function describe(code) {
        return ({
            0: "Céu limpo", 1: "Quase limpo", 2: "Parcialmente nublado", 3: "Nublado",
            45: "Neblina", 48: "Neblina com geada",
            51: "Garoa fraca", 53: "Garoa", 55: "Garoa forte", 56: "Garoa congelante", 57: "Garoa congelante",
            61: "Chuva fraca", 63: "Chuva", 65: "Chuva forte", 66: "Chuva congelante", 67: "Chuva congelante",
            71: "Neve fraca", 73: "Neve", 75: "Neve forte", 77: "Grãos de neve",
            80: "Pancadas de chuva", 81: "Pancadas de chuva", 82: "Pancadas fortes",
            85: "Pancadas de neve", 86: "Pancadas de neve",
            95: "Tempestade", 96: "Tempestade com granizo", 99: "Tempestade com granizo"
        })[code] ?? "—";
    }

    function icon(kind, day) {
        return ({
            clear: day ? "sunny" : "clear_night",
            partly: day ? "partly_cloudy_day" : "partly_cloudy_night",
            cloudy: "cloud", fog: "foggy", drizzle: "rainy_light", rain: "rainy",
            snow: "weather_snowy", storm: "thunderstorm"
        })[kind] ?? "cloud";
    }

    // Where the wind comes from, on a 16-point rose
    function compass(deg) {
        const names = ["N", "NNE", "NE", "ENE", "L", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"];
        return names[Math.round(((deg % 360) + 360) % 360 / 22.5) % 16];
    }

    // ── Fetching ─────────────────────────────────────
    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text).results ?? [];
                    root.results = r.map(p => ({
                        name: p.name, region: p.admin1 ?? "", country: p.country ?? "",
                        lat: p.latitude, lon: p.longitude
                    }));
                    root.searchStatus = root.results.length ? "" : "none";
                    if (root._pick && root.results.length) root.choose(root.results[0]);
                } catch (e) {
                    root.searchStatus = "error";
                }
            }
        }
        onExited: (code, status) => { if (code !== 0) root.searchStatus = "error"; }
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const f = JSON.parse(text), c = f.current, h = f.hourly;
                    root.current = {
                        temp: c.temperature_2m, feels: c.apparent_temperature,
                        code: c.weather_code, kind: root.kind(c.weather_code), day: c.is_day === 1,
                        windSpeed: c.wind_speed_10m, windDir: c.wind_direction_10m
                    };
                    const out = [];
                    // The first hour is the one under way
                    for (let i = 1; i < h.time.length && out.length < 6; i++) {
                        out.push({
                            time: h.time[i].slice(11, 16),
                            temp: h.temperature_2m[i], feels: h.apparent_temperature[i],
                            code: h.weather_code[i], kind: root.kind(h.weather_code[i]), day: h.is_day[i] === 1,
                            rain: h.precipitation_probability[i] ?? 0,
                            windSpeed: h.wind_speed_10m[i], windDir: h.wind_direction_10m[i]
                        });
                    }
                    root.hours = out;
                    root.updated = new Date();
                    root.status = "ok";
                } catch (e) {
                    root.status = "error";
                }
            }
        }
        onExited: (code, status) => { if (code !== 0) root.status = "error"; }
    }

    Timer {
        running: root.hasPlace && st.shown
        interval: 15 * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Written once a change settles: writing after each field of a city
    // (or of a position) made the file view load it back half done
    Timer {
        id: save
        interval: 300
        onTriggered: stateFile.writeAdapter()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("weather.json")
        blockLoading: true
        onAdapterUpdated: save.restart()
        onLoadFailed: writeAdapter()
        JsonAdapter {
            id: st
            property string name: ""
            property string region: ""
            property string country: ""
            property real lat: 0
            property real lon: 0
            property bool shown: true
            property string screen: ""      // empty: the first screen
            property real x: -1              // top left of the widget on its screen; -1: not placed yet
            property real y: -1
        }
    }
}
