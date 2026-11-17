import QtQuick

// Annabelle's ear for music. Fed each frame of the spectrum (listen()), it
// finds the tempo itself: the rise of the spectrum from frame to frame
// (spectral flux) marks the onsets, the autocorrelation of the last 8 s of
// onsets gives the beat period, and lining a comb of that period up with
// them gives where the beats fall. A clock running at that tempo and nudged
// onto those beats drives her moves, so they land on the beat instead of a
// moment after it and carry on through a bar the drums sit out. (The bass
// peaks MusicFx calls beats come too seldom outside dance music for this;
// they arrive through beat() as accents.) How hard the music pushes (drive)
// sets how she dances:
//
//   calm   sleepy eyes, a slow sway, a small nod, chewing, eyes shut a while
//   groove knees bounce down on each beat, the head nods, a hoof taps on each
//   hot    double-time tap dance, ears flicking, a headbang, jumps that last
//          one beat so she lands on the next (half a beat in a slow song)
//
// A passage much quieter than the song so far shuts her eyes; when the music
// comes back she jumps with wide eyes. The voice range of the spectrum opens
// her mouth when she sings along (always with a microphone, often while a
// line of the lyrics is being sung).
QtObject {
    id: root

    // ── What she hears, set by Annabelle ──────────────────
    property var bars: []
    property real level: 0
    property bool lyricLine: false
    property bool mic: false
    property bool punk: false
    property real abduct: 0          // 0..1, a UFO beam lifting her
    property bool watching: false    // something to look at, at lookX/lookY
    property real lookX: 0
    property real lookY: 0

    // ── Beat clock ────────────────────────────────────────
    property real period: 0.5        // seconds per beat
    property real phase: 0           // beats; whole numbers fall on beats
    property real confidence: 0      // how clear the beat is, 0..1
    property real drive: 0           // how hard the music pushes, 0..1
    property bool quiet: false       // in a quiet passage

    // ── Pose, read by Sheep ───────────────────────────────
    property real air: 0
    property real bob: 0
    property real sway: 0
    property real tilt: 0
    property real squash: 0
    property real nod: 0
    property real earBack: 0
    property real earFront: 0
    property real lidL: 0.5
    property real lidR: 0.5
    property real eyeScale: 1
    property real pupilX: -0.2
    property real pupilY: 0.35
    property real cross: 0
    property real mouth: 0
    property real mouthRound: 0
    property real tongue: 0
    property real tap0: 0
    property real tap1: 0
    property real tap2: 0
    property real tap3: 0
    property real dangle: 0
    property real hair: 0

    signal sang()        // a sung note: a ♪ can float up from her mouth

    function spr(x) {
        return { x: x, v: 0 };
    }

    readonly property int history: 480   // spectrum frames of onsets kept, 8 s
    readonly property var tapOrders: [[0, 3, 1, 2], [0, 1, 0, 1]]   // diagonals, front pair

    property var st: ({
        t: 0, beatIdx: 0, accent: 0,
        prev: [], odf: [], pos: 0, count: 0, odfMean: 0.3, odfAvg: 0.3, sinceTempo: 0,
        lag: 0, pendingLag: 0, pendingCount: 0, nudge: 0, fps: 60, frames: 0, fpsT: 0, clock: 0,
        locked: false, clear: 0, pendErr: 0, pendCount: 0,
        energy: 0, song: 0, fast: 0, mid: 0, midAvg: 0.05,
        quietFor: 0, quietLen: 0, drop: false,
        airborne: false, abducted: false, dizzy: false, y: 0, vy: 0, g: 1500, jumpCool: 0,
        bob: spr(0), nod: spr(0), sway: spr(0), tilt: spr(0), sq: spr(0),
        earB: spr(0), earF: spr(0), excite: spr(0), hair: spr(0),
        lidL: spr(0.5), lidR: spr(0.5), wide: spr(1), px: spr(-0.2), py: spr(0.35), cross: spr(0),
        tongue: spr(0), taps: [spr(0), spr(0), spr(0), spr(0)],
        m: 0, round: 0, vowel: 0, open: false, lastNote: 0, sing: false, pattern: 0,
        blinkAt: 2.5, blinkUntil: 0, glanceAt: 5, glanceUntil: 0, gx: 0, gy: 0,
        face: "", faceUntil: 0, faceSeq: 0,
        chewAt: 6, chewUntil: 0, blepUntil: 0, savorAt: 10, savorUntil: 0,
        prevY: 0, prevNod: 0
    })

    function lerp(a, b, t) {
        return a + (b - a) * t;
    }
    function clamp(x, a, b) {
        return Math.max(a, Math.min(b, x));
    }
    function smooth(a, b, x) {
        const t = clamp((x - a) / (b - a), 0, 1);
        return t * t * (3 - 2 * t);
    }
    function ema(cur, x, dt, tau) {
        return cur + (x - cur) * (1 - Math.exp(-dt / tau));
    }
    // A damped spring {x, v} pulled to target: k stiffness, z damping ratio
    function spring(s, target, k, z, dt) {
        const n = Math.ceil(dt / 0.005), h = dt / n, c = 2 * z * Math.sqrt(k);
        for (let i = 0; i < n; i++) {
            s.v += (k * (target - s.x) - c * s.v) * h;
            s.x += s.v * h;
        }
        return s.x;
    }

    function setFace(name, seconds) {
        st.face = name;
        st.faceUntil = st.t + seconds;
    }

    // A bass peak MusicFx heard: an accent she feels in the body. It comes
    // after the beat it marks, so once her clock has the beat it barely moves her
    function beat(strength) {
        const S = st;
        S.accent = Math.max(S.accent, strength);
        S.bob.v += 55 * strength * (0.4 + drive) * (1 - 0.75 * smooth(0.25, 0.6, confidence));
        if (strength > 0.8 && drive > 0.45) S.excite.v += 2.2;
    }

    function ago(i) {
        return st.odf[((st.pos - 1 - i) % history + history) % history] ?? 0;
    }

    // One frame of the spectrum, 64 bands in 0..1
    function listen(v) {
        const S = st;
        if (!v || v.length < 64) return;
        // Onset strength: how much the (log) spectrum rose, the lows most
        let flux = 0;
        for (let i = 0; i < 64; i++) {
            const x = Math.log(1 + 10 * v[i]);
            const d = x - (S.prev[i] ?? x);
            S.prev[i] = x;
            if (d > 0) flux += d * (i < 10 ? 1.5 : i < 36 ? 1 : 0.6);
        }
        S.odf[S.pos] = flux;
        S.pos = (S.pos + 1) % history;
        S.count++;
        S.odfAvg = S.odfAvg + (flux - S.odfAvg) * 0.004;
        // A strong onset is an accent too
        if (flux > S.odfMean * 2.2 && flux > 0.5) S.accent = Math.max(S.accent, Math.min(1, flux / (S.odfMean * 5 + 0.1)));
        S.odfMean = S.odfMean + (flux - S.odfMean) * 0.03;

        // The spectrum's frame rate, measured on the real time step() is
        // given (not the time she moves by, clamped through a hitch)
        S.frames++;
        if (S.clock - S.fpsT > 2) {
            S.fps = Math.max(20, Math.min(120, S.fps + (S.frames / (S.clock - S.fpsT) - S.fps) * 0.5));
            S.frames = 0;
            S.fpsT = S.clock;
        }
        if (++S.sinceTempo >= 30 && S.count >= 180) {
            S.sinceTempo = 0;
            tempo();
            if (S.lag > 0) align();
        }
    }

    // The beat period from the autocorrelation of the onsets: the lag (in
    // frames) where they best repeat, between ~70 and ~170 bpm, leaning to
    // ~120 and to lags whose double repeats too
    function tempo() {
        const S = st, n = Math.min(S.count, history);
        const w = new Array(n);
        let m = 0, e = 0;
        for (let i = 0; i < n; i++) {
            w[i] = ago(n - 1 - i);
            m += w[i];
        }
        m /= n;
        for (let i = 0; i < n; i++) {
            w[i] -= m;
            e += w[i] * w[i];
        }
        if (e < 1e-6) {
            confidence = Math.max(0, confidence - 0.1);
            return;
        }
        const acf = [];
        for (let lag = 20; lag <= 106; lag++) {
            let s = 0;
            for (let i = lag; i < n; i++) s += w[i] * w[i - lag];
            acf[lag] = s / e;
        }
        let best = 0, score = -9;
        for (let lag = 21; lag <= 53; lag++) {
            const pref = Math.exp(-0.5 * Math.pow(Math.log2(3600 / lag / 118) / 0.8, 2));
            const sc = acf[lag] * (0.55 + 0.45 * pref) + 0.25 * Math.max(0, acf[2 * lag]);
            if (sc > score) {
                score = sc;
                best = lag;
            }
        }
        const y0 = acf[best - 1], y1 = acf[best], y2 = acf[best + 1];
        const den = y0 - 2 * y1 + y2;
        let cand = best + (den < 0 ? Math.max(-0.5, Math.min(0.5, 0.5 * (y0 - y2) / den)) : 0);
        confidence += (Math.max(0, Math.min(1, y1)) - confidence) * 0.35;
        if (S.lag === 0) {
            S.lag = cand;
        } else {
            // Half or double the current tempo is the same beat: keep the octave
            if (Math.abs(cand * 2 - S.lag) < S.lag * 0.06) cand *= 2;
            else if (Math.abs(cand / 2 - S.lag) < S.lag * 0.06) cand /= 2;
            if (Math.abs(cand - S.lag) < S.lag * 0.08) {
                S.lag += (cand - S.lag) * 0.4;
                S.pendingCount = 0;
            } else if (Math.abs(cand - S.pendingLag) < cand * 0.04 && ++S.pendingCount >= 3) {
                // A new tempo only once it has held for a few looks
                S.lag = cand;
                S.pendingCount = 0;
            } else if (Math.abs(cand - S.pendingLag) >= cand * 0.04) {
                S.pendingLag = cand;
                S.pendingCount = 1;
            }
        }
        period = Math.max(0.33, Math.min(1.0, S.lag / S.fps));
    }

    // Where the beats fall: the offset at which a comb with the beat's period
    // catches most onsets (recent ones count more). The clock goes straight
    // there on finding the beat, then only follows small drifts, a little at a
    // time; a beat that seems to have moved a long way must say so several
    // looks running, and a stretch with no clear beat moves it not at all.
    // The spectrum trails the sound by about `latency`, so her beat is set
    // that much ahead of where the onsets put it.
    readonly property real latency: 0.08
    function align() {
        const S = st, L = S.lag, n = Math.min(S.count, history);
        const K = Math.floor((n - 2) / L);
        if (K < 2) return;
        if (confidence < 0.12) {
            S.locked = false;
            return;
        }
        let best = 0, top = -1, sum = 0;
        const O = Math.ceil(L);
        for (let o = 0; o < O; o++) {
            let s = 0;
            for (let k = 0; k < K; k++) {
                const p = o + k * L, i = Math.floor(p), f = p - i;
                s += (ago(i) * (1 - f) + ago(i + 1) * f) * (1 - 0.5 * k / K);
            }
            sum += s;
            if (s > top) {
                top = s;
                best = o;
            }
        }
        S.clear = top / Math.max(1e-6, sum / O);
        // The last beat was `best` frames ago, plus a frame for the onset's rise
        const want = (best + 1) / L + latency / period, f = phase - Math.floor(phase);
        let err = f - want;
        err -= Math.round(err);
        if (!S.locked) {
            if (S.clear < 1.4) return;
            S.locked = true;
            S.nudge = -err;
        } else if (S.clear < 1.25) {
            S.pendCount = 0;
        } else if (Math.abs(err) > 0.2) {
            let de = err - S.pendErr;
            de -= Math.round(de);
            if (Math.abs(de) < 0.1) S.pendCount++;
            else {
                S.pendErr = err;
                S.pendCount = 1;
            }
            // A song's beat doesn't move, its accents do: with a clear beat
            // in hand it takes 4 s of the beat elsewhere to follow it
            if (S.pendCount >= (confidence > 0.4 ? 8 : 3)) {
                S.nudge = -err;
                S.pendCount = 0;
            }
        } else {
            S.pendCount = 0;
            S.nudge = clamp(-err * 0.5, -0.05, 0.05);
        }
    }

    // How far (in cycles) a spring(k, z) trails a target swinging at w rad/s
    function trail(k, z, w) {
        return Math.atan2(2 * z * Math.sqrt(k) * w, k - w * w) / (2 * Math.PI);
    }

    // Something bounced off her
    function bonk() {
        const S = st;
        S.sq.v += 2.6;
        S.nod.v += 240;
        S.earB.v -= 220;
        S.earF.v -= 260;
        setFace("squint", 0.45);
    }

    // A new song: ears up, a look at you. Its beat is found afresh from its
    // own onsets: the ear starts empty, and she keeps the old time until it has
    // heard 3 s of the new one
    function surprise() {
        const S = st;
        S.odf = [];
        S.prev = [];
        S.pos = 0;
        S.count = 0;
        S.sinceTempo = 0;
        S.lag = 0;
        S.pendingCount = 0;
        S.pendCount = 0;
        S.locked = false;
        confidence *= 0.5;
        S.excite.v += 5;
        setFace("wide", 1.2);
        S.gx = 0.1;
        S.gy = 0;
        S.glanceUntil = S.t + 1.8;
        S.glanceAt = S.glanceUntil + 3;
    }

    function jump(height) {
        const S = st;
        // In the air for one beat, up now and down on the next one; in a slow
        // song (a beat over 0.7 s) for half of one
        const T = period > 0.7 ? period / 2 : period;
        S.g = 8 * height / (T * T);
        S.vy = -S.g * T / 2;
        S.airborne = true;
        S.jumpCool = 2;
        S.sq.v -= 2.4;
    }

    function step(dt) {
        const S = st;
        S.clock += dt;
        dt = clamp(dt, 0.001, 0.05);
        S.t += dt;
        const t = S.t;

        // ── Listen ──
        const b = bars;
        let mid = 0;
        if (b && b.length >= 64) {
            for (let i = 5; i < 26; i++) mid += b[i];
            mid /= 21;
        }
        S.mid = ema(S.mid, mid, dt, mid > S.mid ? 0.025 : 0.09);
        S.midAvg = ema(S.midAvg, mid, dt, 5);
        S.energy = ema(S.energy, level, dt, 2.5);
        S.song = ema(S.song, level, dt, 10);
        S.fast = ema(S.fast, level, dt, 0.35);
        S.accent *= Math.exp(-dt * 3);

        // ── Beat clock, eased onto where the beats fall ──
        const ease = S.nudge * Math.min(1, dt * 5);
        S.nudge -= ease;
        if (S.odfAvg < 0.05) confidence = Math.max(0, confidence - dt * 0.3);
        phase += dt / period + ease;
        const idx = Math.floor(phase);
        const onBeat = idx > S.beatIdx;
        if (onBeat) S.beatIdx = idx;

        // ── How hard the music pushes: loudness, busy onsets, a clear beat ──
        const loud = clamp((S.energy - 0.03) / 0.19, 0, 1);
        const busy = clamp(S.odfAvg / 1.0, 0, 1);
        const pulse = clamp((confidence - 0.1) / 0.5, 0, 1);
        drive = ema(drive, clamp(0.3 * loud + 0.35 * busy + 0.35 * pulse, 0, 1), dt, 1.5);
        const v = drive;
        const calm = 1 - smooth(0.2, 0.5, v);
        const hot = smooth(0.55, 0.9, v);

        // Quiet passage: well under the song's own average
        const ratio = S.fast / Math.max(0.03, S.song);
        if (S.song > 0.05 && ratio < 0.42) S.quietFor += dt;
        else S.quietFor = Math.max(0, S.quietFor - dt * 3);
        const nowQuiet = S.quietFor > 1.2;
        if (quiet && !nowQuiet && S.quietLen > 2.5) S.drop = true;
        S.quietLen = nowQuiet ? S.quietLen + dt : 0;
        quiet = nowQuiet;

        // ── On each beat of her clock ──
        if (onBeat) {
            if (!S.airborne && !S.abducted && abduct < 0.02 && S.jumpCool <= 0 && !quiet) {
                let p = 0;
                if (S.drop) p = 1;
                else if (v > 0.5)
                    p = (idx % 4 === 0 ? 0.3 : 0.05) + hot * 0.3 + (punk ? 0.25 : 0) + S.accent * 0.15;
                if (Math.random() < p) jump(lerp(16, 32, v) * (S.drop ? 1.35 : 1));
            }
            if (S.drop) {
                setFace("wide", period + 0.5);
                S.excite.v += 6;
                S.drop = false;
            }
            S.jumpCool--;
            if (v > 0.45 && Math.random() < 0.35) (idx % 2 ? S.earB : S.earF).v += 260 * v;
            if (v > 0.55 && S.face === "" && Math.random() < 0.035)
                setFace(["tongue", "wink", "squint"][idx % 3], period * 2);
            if (abduct > 0.3 && idx % 2 === 0)
                setFace(["wide", "tongue", "wink", "squint"][S.faceSeq++ % 4], period * 2);
            if (idx % 8 === 0) {
                // Sing this stretch? Always with the mic, often with the lyrics
                S.sing = mic || (lyricLine ? Math.random() < 0.65 : v > 0.4 && Math.random() < 0.2);
            }
            if (idx % 16 === 0) S.pattern = Math.random() < 0.6 ? 0 : 1;
            if (calm < 0.5 && Math.random() < 0.012) S.blepUntil = t + period * 3;
        }
        if (t > S.faceUntil) S.face = "";
        const face = S.face;

        // ── Off the ground ──
        if (abduct > 0.02) {
            S.abducted = true;
            S.airborne = false;
            const target = -38 * abduct + Math.sin(t * 2.6) * 4 * abduct;
            S.y += (target - S.y) * (1 - Math.exp(-dt * 3));
            S.vy = 0;
        } else if (S.abducted) {
            S.abducted = false;
            if (S.y < -1) {
                S.airborne = true;
                S.vy = 0;
                S.g = 1300;
                S.dizzy = true;
            }
        }
        if (S.airborne) {
            S.vy += S.g * dt;
            S.y += S.vy * dt;
            if (S.y >= 0) {
                S.y = 0;
                S.airborne = false;
                S.sq.v += 2 + Math.min(4, S.vy / 120);
                S.bob.v += S.vy * 0.25;
                if (S.dizzy) {
                    setFace("dizzy", 1.6);
                    S.dizzy = false;
                }
            }
        }
        air = S.y;
        const up = S.airborne || S.abducted;

        // ── Body: knees down on the beat, a sway over two beats ──
        // The springs that smooth each move trail it, so each is led by its
        // spring's trail at the beat's frequency to bottom out on the beat
        const w = 2 * Math.PI / period;
        const down = 0.5 + 0.5 * Math.cos(2 * Math.PI * (phase + trail(500, 0.8, w)));
        const late = 0.5 + 0.5 * Math.cos(2 * Math.PI * (phase + trail(300, 0.55, w) - 0.06));
        const half = Math.sin(Math.PI * (phase + 2 * trail(120, 0.9, w / 2)));
        const halfT = Math.sin(Math.PI * (phase + 2 * trail(150, 0.8, w / 2)));
        bob = spring(S.bob, down * lerp(2.5, 10, v) * (quiet ? 0.25 : 1) * (up ? 0.3 : 1), 500, 0.8, dt);
        sway = spring(S.sway, half * lerp(4, 2.5, v) * (quiet ? 1.6 : 1), 120, 0.9, dt);
        tilt = spring(S.tilt, halfT * lerp(2.5, 1.5, v) * (quiet ? 1.8 : 1)
            - (S.airborne ? S.vy * 0.012 : 0) + (S.abducted ? Math.sin(t * 2.1) * 7 * abduct : 0), 150, 0.8, dt);
        squash = spring(S.sq, 0, 320, 0.35, dt);

        // Head: nods to the beat, a headbang when hot, rocking when quiet
        const nodAmp = lerp(6.5, 15, v) * (punk ? 1.5 : 1);
        nod = spring(S.nod, quiet ? 5 + 4 * half : late * nodAmp - 2, 300, 0.55, dt);

        // Hooves: the one due on the next beat rises and stomps on it, in turn
        // (diagonals, or the front pair), twice a beat when hot
        const order = tapOrders[S.pattern];
        const rate = hot > 0.5 ? 2 : 1;
        const p2 = phase * rate + trail(900, 0.9, w * rate), g2 = p2 - Math.floor(p2);
        const due = order[(Math.floor(p2) + 1) % 4];
        const lift = g2 > 0.45 ? Math.sin(Math.PI * (g2 - 0.45) / 0.55) : 0;
        const tapAmp = !quiet && !up && v > 0.22 ? lerp(5, 14, v) / (rate > 1 ? 1.3 : 1) : 0;
        for (let k = 0; k < 4; k++) spring(S.taps[k], k === due ? lift * tapAmp : 0, 900, 0.9, dt);
        tap0 = Math.max(0, S.taps[0].x);
        tap1 = Math.max(0, S.taps[1].x);
        tap2 = Math.max(0, S.taps[2].x);
        tap3 = Math.max(0, S.taps[3].x);
        dangle = up ? Math.sin(t * 9) * 0.14 + Math.sin(t * 3.3) * 0.3 * abduct : 0;

        // Ears: up with excitement, flapping behind the head's moves
        const headY = bob + air;
        const vy = (headY - S.prevY) / dt;
        S.prevY = headY;
        const ex = spring(S.excite, hot * 0.2 + (abduct > 0.02 ? 1 : 0) + (face === "wide" ? 0.8 : 0), 40, 0.7, dt);
        const lag = clamp(vy * 0.06, -30, 40);
        earBack = spring(S.earB, ex * 75 + lag + (quiet ? -6 : 0), 160, 0.25, dt);
        earFront = spring(S.earF, ex * 115 + lag * 1.2 + (quiet ? -6 : 0), 140, 0.25, dt);
        const nodVel = (nod - S.prevNod) / dt;
        S.prevNod = nod;
        hair = spring(S.hair, clamp(-nodVel * 0.08, -16, 16), 220, 0.25, dt);

        // ── Face ──
        // Her classic sleepy look, more awake as it heats up; eyes shut to
        // savour a calm song or a quiet passage
        let lid = lerp(0.42, 0.68, v);
        if (t > S.savorAt) {
            if (calm > 0.5 || Math.random() < 0.3) S.savorUntil = t + 2.5 + Math.random() * 2.5;
            S.savorAt = t + 9 + Math.random() * 12;
        }
        if (quiet || t < S.savorUntil) lid = 0;
        let lL = lid, lR = lid, wide = 1, cr = 0, tx = -0.25, ty = 0.35;
        let m = 0, round = 0, tg = t < S.blepUntil ? 1 : 0;

        if (watching) {
            tx = lookX;
            ty = lookY;
        } else if (t < S.glanceUntil) {
            tx = S.gx;
            ty = S.gy;
        } else if (t > S.glanceAt) {
            // A glance: at you, or somewhere around
            if (Math.random() < 0.45) {
                S.gx = 0.1;
                S.gy = 0;
            } else {
                S.gx = Math.random() * 2 - 1;
                S.gy = Math.random() * 1.4 - 0.9;
            }
            S.glanceUntil = t + 0.8 + Math.random() * 1.6;
            S.glanceAt = S.glanceUntil + 2 + Math.random() * 5;
        }

        // Singing along with the voice in the song, or chewing
        const vocal = clamp((S.mid - S.midAvg * 0.9) / (S.midAvg * 0.8 + 0.03), 0, 1);
        if (S.sing && !quiet && !up) {
            m = clamp(vocal * 1.15, 0, 1);
            if (m > 0.45 && !S.open) {
                S.open = true;
                S.vowel = Math.random();
                if (t - S.lastNote > 0.7 && Math.random() < 0.5) {
                    S.lastNote = t;
                    sang();
                }
            } else if (m < 0.2) {
                S.open = false;
            }
            round = S.vowel;
        } else if (t < S.chewUntil) {
            m = 0.12 + 0.12 * Math.sin(t * 10);
            round = 0.6;
        } else if (calm > 0.5 && t > S.chewAt) {
            S.chewUntil = t + 2 + Math.random() * 2;
            S.chewAt = t + 8 + Math.random() * 10;
        }

        switch (face) {
        case "wide":
            lL = lR = 1; wide = 1.28; tx = 0.05; ty = 0; m = Math.max(m, 0.55); round = 1;
            break;
        case "squint":
            lL = lR = 0.1; wide = 0.95; m = Math.max(m, 0.35); round = 0;
            break;
        case "wink":
            lL = 0.85; lR = 0; tg = 0.7;
            break;
        case "tongue":
            lL = lR = 0.4; cr = 1; tx = 0; ty = 0.1; tg = 1;
            break;
        case "dizzy":
            lL = lR = 0.85; tx = Math.cos(t * 11) * 0.8; ty = Math.sin(t * 11) * 0.8;
            break;
        }
        if (t > S.blinkAt) {
            S.blinkUntil = t + 0.13;
            S.blinkAt = t + 2 + Math.random() * 4.5;
        }
        if (t < S.blinkUntil && face !== "wide") lL = lR = 0;

        lidL = clamp(spring(S.lidL, lL, 900, 0.9, dt), 0, 1);
        lidR = clamp(spring(S.lidR, lR, 900, 0.9, dt), 0, 1);
        eyeScale = spring(S.wide, wide, 400, 0.45, dt);
        pupilX = spring(S.px, tx, 700, 0.85, dt);
        pupilY = spring(S.py, ty, 700, 0.85, dt);
        cross = spring(S.cross, cr, 300, 0.8, dt);
        S.m = ema(S.m, m, dt, m > S.m ? 0.03 : 0.07);
        mouth = S.m;
        S.round = ema(S.round, round, dt, 0.06);
        mouthRound = S.round;
        tongue = clamp(spring(S.tongue, tg, 260, 0.6, dt), 0, 1);
    }
}
