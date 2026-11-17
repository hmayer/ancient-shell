#version 440
// The desktop visualizer (wallpaper/Visualizer.qml) in one pass: star streaks
// flying out of the centre, under one of five shapes driven by the spectrum.
//
// After changing this file, rebuild the shader Qt Quick loads:
//     /usr/lib/qt6/bin/qsb --qt6 -o visualizer.frag.qsb visualizer.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;          // item size, px
    float mode;         // 0 bars, 1 wave, 2 mirror, 3 ring, 4 halo, 5 sheep (ring round Annabelle)
    float gain;         // intensity, 0.1 .. 2
    float kick;         // beat pulse, 0 .. 1
    float particles;    // 0 or 1
    float travel;       // how far the streaks have flown (grows with the music)
    float boost;        // their speed right now
    vec4 cyan;
    vec4 cyanBright;
    vec4 cyanDeep;
    vec4 amber;
    // 64 spectrum bands, low to high, four per vector
    vec4 b0; vec4 b1; vec4 b2; vec4 b3; vec4 b4; vec4 b5; vec4 b6; vec4 b7;
    vec4 b8; vec4 b9; vec4 b10; vec4 b11; vec4 b12; vec4 b13; vec4 b14; vec4 b15;
};

const float PI = 3.14159265;
const float TAU = 6.2831853;
const int BANDS = 64;
const float SPREAD = 128.0;   // the bands laid out mirrored, highs at both ends
const float SHEEP_R = 0.25;   // Annabelle's window, as a share of the shorter side (Visualizer.qml)

float band(int i) {
    i = clamp(i, 0, BANDS - 1);
    int k = i / 4;
    vec4 v = k == 0 ? b0 : k == 1 ? b1 : k == 2 ? b2 : k == 3 ? b3
           : k == 4 ? b4 : k == 5 ? b5 : k == 6 ? b6 : k == 7 ? b7
           : k == 8 ? b8 : k == 9 ? b9 : k == 10 ? b10 : k == 11 ? b11
           : k == 12 ? b12 : k == 13 ? b13 : k == 14 ? b14 : b15;
    int c = i - k * 4;
    return c == 0 ? v.x : c == 1 ? v.y : c == 2 ? v.z : v.w;
}

// Position p of 0..127 across the mirrored layout: bass in the middle
float mirrored(int p) {
    p = clamp(p, 0, 127);
    return p < BANDS ? band(BANDS - 1 - p) : band(p - BANDS);
}

// Going round a circle the layout wraps
float around(int p) {
    p = ((p % 128) + 128) % 128;
    return mirrored(p);
}

float catmull(float p0, float p1, float p2, float p3, float t) {
    float t2 = t * t, t3 = t2 * t;
    return max(0.0, 0.5 * (2.0 * p1 + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
        + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3));
}

// Smooth value at a continuous position of the mirrored layout
float smoothLine(float x) {
    int i = int(floor(x));
    return catmull(mirrored(i - 1), mirrored(i), mirrored(i + 1), mirrored(i + 2), fract(x));
}

float smoothRound(float x) {
    int i = int(floor(x));
    return catmull(around(i - 1), around(i), around(i + 1), around(i + 2), fract(x));
}

// Paint `col` with coverage `a` over what is there (premultiplied)
vec4 over(vec4 dst, vec4 col, float a) {
    a = clamp(a * col.a, 0.0, 1.0);
    return vec4(col.rgb * a, a) + dst * (1.0 - a);
}

float hash(float n) {
    return fract(sin(n * 12.9898 + 78.233) * 43758.5453);
}

// Streaks flying out of the centre, faster as the music gets louder
vec4 streaks(vec2 px, vec4 col) {
    vec2 d = px - size * 0.5;
    float dist = length(d);
    float far = length(size) * 0.5;
    float ang = atan(d.y, d.x) / TAU + 0.5;
    for (int layer = 0; layer < 3; layer++) {
        float sectors = 70.0 + 45.0 * float(layer);
        float a = ang * sectors;
        float cell = floor(a);
        float seed = cell + 131.0 * float(layer);
        float speed = 0.35 + 0.9 * hash(seed + 0.7);
        float t = fract(hash(seed) + travel * speed * 0.12);
        float head = far * t * t;
        float len = min(far * 0.18, 3.0 + head * 0.06 * speed * boost);
        float along = head - dist;                       // the tail trails inward
        float lit = smoothstep(-1.0, 0.0, along) * smoothstep(len + 1.0, len, along);
        float off = (a - cell - (0.2 + 0.6 * hash(seed + 3.3))) * TAU / sectors * dist;
        float thin = smoothstep(1.6, 0.4, abs(off));
        float fade = min(1.0, head / (far * 0.3)) * 0.85;
        vec4 c = speed > 1.0 ? vec4(1.0, 0.82, 0.54, 1.0) : cyanBright;
        col = over(col, c, lit * thin * fade);
    }
    return col;
}

// Bars rising from the bottom edge
vec4 bars(vec2 px, vec4 col) {
    float step = size.x / SPREAD;
    float p = floor(px.x / step);
    float local = (fract(px.x / step) - 0.5) * step;
    float h = max(3.0, mirrored(int(p)) * size.y * 0.31 * gain);
    float up = size.y - px.y;
    float inside = smoothstep(step * 0.31 + 0.6, step * 0.31 - 0.6, abs(local)) * smoothstep(h + 0.6, h - 0.6, up);
    float t = clamp(up / h, 0.0, 1.0);
    vec4 c = t > 0.65 ? mix(cyan * vec4(1, 1, 1, 0.7), cyanBright * vec4(1, 1, 1, 0.95), (t - 0.65) / 0.35)
                      : mix(cyanDeep * vec4(1, 1, 1, 0.25), cyan * vec4(1, 1, 1, 0.7), t / 0.65);
    return over(col, c, inside);
}

// A lit line along the bottom, a glow under it and an amber echo
vec4 wave(vec2 px, vec4 col) {
    float base = size.y * 0.86;
    float amp = size.y * 0.22 * gain;
    float x = px.x / size.x * (SPREAD - 1.0);
    float v = smoothLine(x);
    float y = base - v * amp;
    float slope = (smoothLine(x + 0.5) - smoothLine(x - 0.5)) * amp / (size.x / (SPREAD - 1.0));
    float dist = abs(px.y - y) / sqrt(1.0 + slope * slope);
    if (px.y > y) {
        float t = clamp((px.y - (base - amp)) / (size.y - (base - amp)), 0.0, 1.0);
        col = over(col, cyan, 0.35 * (1.0 - t));
    }
    float echo = base + (base - y) * 0.35;
    col = over(col, amber, 0.5 * smoothstep(1.4, 0.4, abs(px.y - echo) / sqrt(1.0 + slope * slope * 0.12)));
    return over(col, cyanBright, smoothstep(2.2, 1.0, dist));
}

// Rounded bars up and down from the middle
vec4 mirror(vec2 px, vec4 col) {
    float step = size.x / SPREAD;
    float p = floor(px.x / step);
    float local = (fract(px.x / step) - 0.5) * step;
    float v = mirrored(int(p));
    float h = max(3.0, v * size.y * 0.56 * gain);
    float w = max(1.0, step * 0.17);
    vec2 q = vec2(abs(local), max(0.0, abs(px.y - size.y * 0.5) - h * 0.5 + w));
    float inside = smoothstep(w + 0.6, w - 0.6, length(q));
    col = over(col, cyan, 0.35 * smoothstep(1.0, 0.0, abs(px.y - size.y * 0.5)));
    return over(col, cyanBright, inside * (0.4 + 0.5 * v));
}

// Spokes round a circle, like a gate's inner ring. With a window in the
// middle (Annabelle, drawn by the QML item over it) the circle is wider, the
// spokes shorter and the amber ring goes round the outside instead
vec4 ring(vec2 px, vec4 col, bool window) {
    float r = min(size.x, size.y) * (window ? SHEEP_R : 0.16);
    // (the ring round the window stays put, with the window and its rim)
    vec2 d = (px - size * 0.5) / (window ? 1.0 : 1.0 + kick * 0.05 * gain);
    float dist = length(d);
    col = over(col, cyan, 0.75 * smoothstep(1.6, 0.6, abs(dist - r)));
    col = over(col, amber, 0.35 * smoothstep(1.0, 0.2, abs(dist - r * (window ? 1.035 : 0.9))));
    float a = fract(atan(d.x, -d.y) / TAU) * SPREAD;
    float idx = floor(a + 0.5);
    float v = around(int(idx));
    float w = max(1.0, r * (window ? 0.0125 : 0.0175));
    float len = 6.0 + v * r * (window ? 0.62 : 1.1) * gain;
    float off = (a - idx) * TAU / SPREAD * dist;
    float from = r * (window ? 1.035 : 1.0) + 8.0;
    vec2 q = vec2(abs(off), max(0.0, abs(dist - from - len * 0.5) - len * 0.5 + w));
    float inside = smoothstep(w + 0.7, w - 0.7, length(q));
    return over(col, cyanBright, inside * (0.55 + 0.45 * v));
}

// A blob pulsing round the cover art (drawn on top by the QML item)
vec4 halo(vec2 px, vec4 col) {
    float r = min(size.x, size.y) * 0.13;
    vec2 d = (px - size * 0.5) / (1.0 + kick * 0.06 * gain);
    float dist = length(d);
    float a = fract(atan(d.x, -d.y) / TAU) * SPREAD;
    float v = smoothRound(a);
    float outer = r * 1.12 + v * r * 1.1 * gain;
    float inner = r * 1.04 + v * r * 0.55 * gain;
    col = over(col, cyan, 0.22 * smoothstep(outer + 1.0, outer - 1.0, dist));
    col = over(col, cyan, 0.5 * smoothstep(1.5, 0.5, abs(dist - outer)));
    return over(col, cyanBright, 0.85 * smoothstep(inner + 1.0, inner - 1.0, dist));
}

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec4 col = vec4(0.0);
    if (particles > 0.5) col = streaks(px, col);
    if (mode < 0.5) col = bars(px, col);
    else if (mode < 1.5) col = wave(px, col);
    else if (mode < 2.5) col = mirror(px, col);
    else if (mode < 3.5) col = ring(px, col, false);
    else if (mode < 4.5) col = halo(px, col);
    else col = ring(px, col, true);
    fragColor = col * qt_Opacity;
}
