#version 440
// A closing window sucked into a stargate (windowfx/GateClose.qml).
// `source` is the screen as it was before the window closed; only the
// window's rectangle of it is drawn, swirled into the event horizon of a
// gate that opens over the window's centre, then collapses and sends out a
// shock wave.
//
// After changing this file, rebuild the shader Qt Quick loads:
//     /usr/lib/qt6/bin/qsb --qt6 -o gate.frag.qsb gate.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;          // screen, px
    vec4 rect;          // window: x, y, w, h, px
    float t;            // 0 .. 1 through the effect
    float time;         // seconds, for the ripples
    vec4 horizon;       // event horizon colours
    vec4 rim;
    vec4 stone;
    vec4 chevron;
};

layout(binding = 1) uniform sampler2D source;

const float PI = 3.14159265;
const float TAU = 6.2831853;

vec4 over(vec4 dst, vec4 col, float a) {
    a = clamp(a * col.a, 0.0, 1.0);
    return vec4(col.rgb * a, a) + dst * (1.0 - a);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

// Height across the ring (0 inside .. 1 outside): inner lip, glyph track,
// outer ring, with grooves between
float relief(float b) {
    float lip = smoothstep(0.0, 0.05, b) * (1.0 - smoothstep(0.12, 0.17, b));
    float track = (smoothstep(0.17, 0.22, b) * (1.0 - smoothstep(0.68, 0.73, b))) * 0.7;
    float rim = smoothstep(0.73, 0.78, b) * (1.0 - smoothstep(0.94, 1.0, b));
    return lip + track + rim;
}

// Brushed steel lit from the top left
vec3 metal(vec3 base, vec3 n, float grain) {
    vec3 L = normalize(vec3(-0.45, -0.65, 0.6));
    float dif = max(dot(n, L), 0.0);
    vec3 h = normalize(L + vec3(0.0, 0.0, 1.0));
    float sp = pow(max(dot(n, h), 0.0), 40.0);
    return base * (0.25 + 0.95 * dif) * (0.88 + 0.24 * grain) + vec3(0.8 * sp);
}

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec2 c = rect.xy + rect.zw * 0.5;
    vec2 d = px - c;
    float r = length(d);
    float a = atan(d.y, d.x);

    // The gate: opens, holds, collapses
    float rMax = clamp(min(rect.z, rect.w) * 0.18, 29.0, 156.0);
    float open = smoothstep(0.0, 0.16, t);
    float shut = smoothstep(0.8, 0.95, t);
    float R = rMax * (open * (1.0 + 0.12 * sin(open * PI))) * (1.0 - shut);

    vec4 col = vec4(0.0);

    // ── The window, swirled and pulled in ───────────
    float s = smoothstep(0.1, 0.8, t);
    float reach = length(rect.zw) * 0.5;
    float rn = r / reach;
    float pull = (1.0 + s * 1.6 * exp(-rn * 3.0)) / max(0.02, 1.0 - 0.97 * s);
    float twist = s * (2.5 + 5.0 * s) * exp(-rn * 1.4);
    float sa = a + twist;
    vec2 sp = c + vec2(cos(sa), sin(sa)) * r * pull;
    vec2 inside = step(rect.xy, sp) * step(sp, rect.xy + rect.zw);
    if (inside.x * inside.y > 0.5) {
        vec4 w = texture(source, sp / size);
        // Swallowed at the horizon, gone at the end
        float keep = smoothstep(R * 0.7, R * 1.05, r) * (1.0 - smoothstep(0.7, 0.85, t));
        // Light from the horizon spills over what is falling in
        float lit = s * exp(-max(0.0, r - R) / max(1.0, rMax * 0.6));
        w.rgb = mix(w.rgb, rim.rgb * w.a, 0.5 * lit);
        col = w * keep;
    }

    if (R > 0.5) {
        // ── Glow around the gate ────────────────────
        float glow = exp(-max(0.0, r - R * 1.3) / (rMax * 0.35)) * step(R * 1.26, r);
        col = over(col, rim, 0.3 * glow * open * (1.0 - shut));

        // ── The ring: brushed steel, as on SG-1 ─────
        // Inner lip, the glyph track (it spins while the gate dials), outer
        // ring, with grooves between them
        float inner = R * 1.02, outer = R * 1.3, width = outer - inner;
        float b = (r - inner) / width;
        vec2 ru = d / max(r, 0.001);
        vec2 tu = vec2(-ru.y, ru.x);
        // Light falls from the top left on the whole ring
        float sheen = 0.75 + 0.35 * cos(a + 2.2);
        float ring = smoothstep(inner - 1.0, inner + 1.0, r) * (1.0 - smoothstep(outer - 1.0, outer + 1.0, r));
        if (ring > 0.0) {
            float e = 1.5 / width;
            float slope = (relief(b + e) - relief(b - e)) / (2.0 * e) * 0.22;
            vec3 n = normalize(vec3(-ru * slope, 1.0));
            float grain = noise(vec2(r * 0.7, 0.0) + ru * 2.0);
            vec3 base = stone.rgb * sheen;
            // The glyph track sits a little deeper and darker
            float track = smoothstep(0.18, 0.2, b) * (1.0 - smoothstep(0.7, 0.72, b));
            base *= 1.0 - 0.18 * track;
            vec3 m = metal(base, n, grain);

            // Glyphs carved into the track, 39 of them
            float ag = a + 1.4 * smoothstep(0.0, 0.22, t);
            float cf = (ag / TAU + 1.0) * 39.0;
            float cell = floor(cf), fu = fract(cf);
            float tb = (b - 0.2) / 0.5;
            float divider = 1.0 - smoothstep(0.0, 0.05, min(fu, 1.0 - fu));
            vec2 g = vec2(floor((fu - 0.18) / 0.64 * 3.0), floor((tb - 0.15) / 0.7 * 3.0));
            float inGlyph = step(0.18, fu) * step(fu, 0.82) * step(0.15, tb) * step(tb, 0.85);
            float carved = inGlyph * step(0.52, hash(vec2(cell * 3.0 + g.x, g.y + 11.0)));
            m *= 1.0 - track * (0.45 * carved + 0.35 * divider);

            // The horizon's light on the inner lip
            m += rim.rgb * 0.45 * exp(-(r - inner) / (R * 0.05)) * open;
            col = over(col, vec4(m, 1.0), ring);
        }

        // ── Nine chevrons: steel, each with its lamp ─
        float k = floor((a + PI / 2.0) / TAU * 9.0 + 0.5);
        float ca = k / 9.0 * TAU - PI / 2.0;
        float u = atan(sin(a - ca), cos(a - ca)) * r;
        float au = abs(u);
        float rv = r - (inner + 0.4 * width);
        float len = 0.85 * width;
        float vv = rv / len;
        float hw = R * (0.035 + 0.075 * clamp(vv, 0.0, 1.0));
        float along = smoothstep(-1.0, 1.0, rv) * (1.0 - smoothstep(len - 1.0, len + 1.0, rv));
        float body = (1.0 - smoothstep(hw - 1.0, hw + 1.0, au)) * along;
        // Each casts a shadow on the ring
        float shadow = (1.0 - smoothstep(hw, hw + R * 0.04, au)) * (1.0 - body)
            * smoothstep(-R * 0.03, 0.0, rv) * (1.0 - smoothstep(len, len + R * 0.03, rv));
        col.rgb *= 1.0 - 0.55 * shadow;
        float km = mod(k + 9.0, 9.0);
        float litChev = smoothstep(km * 0.012, km * 0.012 + 0.04, t);
        if (body > 0.0) {
            // Bevelled edges
            float edge = smoothstep(0.65, 1.0, au / hw) + smoothstep(0.8, 1.0, abs(vv * 2.0 - 1.0)) * 0.6;
            vec2 dir = tu * sign(u) * smoothstep(0.65, 1.0, au / hw) + ru * sign(vv - 0.5) * smoothstep(0.8, 1.0, abs(vv * 2.0 - 1.0));
            vec3 n = normalize(vec3(dir.xy * 1.6 * edge, 1.0));
            vec3 m = metal(stone.rgb * 1.35 * sheen, n, noise(vec2(u * 0.8, rv * 0.1)));
            // The lamp: a V of dark glass pointing at the horizon, glowing
            // orange once locked
            float lw = hw * 0.72;
            float vy = (vv - 0.16 - 0.5 * au / hw) * len;
            float lamp = (1.0 - smoothstep(lw - 1.0, lw + 1.0, au))
                * smoothstep(-1.0, 1.0, vy) * (1.0 - smoothstep(len * 0.3 - 1.0, len * 0.3 + 1.0, vy));
            vec3 off = vec3(0.16, 0.05, 0.03);
            vec3 on = chevron.rgb * (1.0 + 0.5 * (1.0 - au / max(lw, 1.0)));
            m = mix(m, mix(off, on, litChev), lamp);
            col = over(col, vec4(m, 1.0), body);
        }
        // A soft glow from a lit lamp
        float halo = exp(-max(0.0, au - hw * 0.4) / (R * 0.03)) * exp(-abs(vv - 0.5) * 3.0) * (1.0 - body);
        col = over(col, chevron, 0.35 * halo * litChev * step(-R * 0.1, rv) * step(rv, len + R * 0.1));

        // ── Event horizon: a rippling blue pool ─────
        if (r < inner) {
            float q = r / inner;
            // Noise taken from the position, not the angle, so it has no seam
            float waves = sin(q * 26.0 - time * 7.0 + noise(ru * 3.0 + vec2(time)) * 3.0);
            float sw = q * 1.6 - time * 0.4;
            vec2 sp2 = mat2(cos(sw), sin(sw), -sin(sw), cos(sw)) * (d / inner) * 4.0;
            float swirl = noise(sp2 + vec2(time * 0.3, -time * 0.2));
            vec4 h = mix(horizon, rim, 0.25 + 0.35 * swirl + 0.15 * waves * (1.0 - q));
            h = mix(h, vec4(1.0), pow(q, 6.0) * 0.6);            // bright rim
            // The kawoosh: a white flash as it forms
            h = mix(h, vec4(1.0), (1.0 - smoothstep(0.08, 0.24, t)) * open);
            col = over(col, h, smoothstep(inner, inner - 1.5, r));
        }
    }

    // ── Collapse flash and shock wave ───────────────
    float wave = smoothstep(0.82, 1.0, t);
    if (wave > 0.0 && wave < 1.0) {
        float wr = rMax * (0.3 + 2.8 * wave);
        float ringW = 3.0 + rMax * 0.08 * (1.0 - wave);
        float sw = exp(-pow((r - wr) / ringW, 2.0));
        col = over(col, rim, sw * (1.0 - wave) * 0.9);
        float flash = exp(-r / (rMax * 0.25)) * (1.0 - smoothstep(0.85, 0.95, t)) * smoothstep(0.8, 0.86, t);
        col = over(col, vec4(1.0), flash);
    }

    fragColor = col * qt_Opacity;
}
