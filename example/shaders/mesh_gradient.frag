#version 460 core

// Login-screen flourish: an animated mesh gradient with noise-driven domain
// warping, replicating the Paper Shaders WebGL background from the iOS demo
// (FCM palette: lilac / orange / yellow). Vivid color regions fold into each
// other like liquid rather than blending to pastel.

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

// Two octaves keeps the organic folds while staying cheap enough for
// low-end GPUs (the emulator's translated GL chokes on more).
float fbm(vec2 p) {
    float v = 0.62 * noise(p);
    v += 0.31 * noise(p * 2.03 + vec2(1.7, 9.2));
    return v;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float aspect = uSize.x / uSize.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    float t = uTime;

    // Liquid domain warp: offset the sample position by animated fbm noise,
    // then warp again through the warped position (the Paper Shaders trick).
    vec2 q = vec2(
        fbm(p * 1.3 + vec2(0.0, t * 0.16)),
        fbm(p * 1.3 + vec2(5.2, -t * 0.13)));
    vec2 r2 = vec2(
        fbm(p * 1.8 + 2.4 * q + vec2(1.7 + t * 0.10, 9.2)),
        fbm(p * 1.8 + 2.4 * q + vec2(8.3, 2.8 - t * 0.12)));
    p += 1.1 * (q - 0.5) + 0.65 * (r2 - 0.5);

    // Slowly orbiting color anchors, spaced wide so each color owns a region.
    vec2 q0 = vec2(-0.55 + 0.30 * sin(t * 0.30), -0.45 + 0.25 * cos(t * 0.24));
    vec2 q1 = vec2( 0.60 + 0.28 * cos(t * 0.27),  0.10 + 0.30 * sin(t * 0.21));
    vec2 q2 = vec2( 0.05 + 0.35 * sin(t * 0.18),  0.60 + 0.25 * cos(t * 0.26));
    vec2 q3 = vec2( 0.50 + 0.25 * sin(t * 0.23), -0.60 + 0.28 * sin(t * 0.19));
    vec2 q4 = vec2(-0.55 + 0.30 * cos(t * 0.21),  0.55 + 0.25 * sin(t * 0.25));

    // FCM palette at full strength.
    vec3 c0 = vec3(0.55, 0.24, 1.00); // lilac
    vec3 c1 = vec3(1.00, 0.60, 0.00); // orange
    vec3 c2 = vec3(1.00, 0.82, 0.22); // yellow
    vec3 c3 = vec3(1.00, 0.72, 0.10); // deep golden
    vec3 c4 = vec3(0.70, 0.42, 1.00); // bright lilac

    // Sharp falloff so regions stay vivid instead of averaging to pastel.
    float w0 = 1.0 / pow(dot(p - q0, p - q0) + 0.02, 2.2);
    float w1 = 1.0 / pow(dot(p - q1, p - q1) + 0.02, 2.2);
    float w2 = 1.0 / pow(dot(p - q2, p - q2) + 0.02, 2.2);
    float w3 = 1.0 / pow(dot(p - q3, p - q3) + 0.02, 2.2);
    float w4 = 1.0 / pow(dot(p - q4, p - q4) + 0.02, 2.2);
    vec3 col = (c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3 + c4 * w4) /
        (w0 + w1 + w2 + w3 + w4);

    // Saturation and brightness lift for the vivid, lit-from-within look.
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = clamp(mix(vec3(lum), col, 1.25) * 1.06, 0.0, 1.0);

    // Soft white sheen drifting across the top (the FluidHighlight).
    float drift = 1.0 - (sin(t * 0.65) + 1.0) / 2.0;
    vec2 sheenCenter = vec2(0.22 + 0.56 * drift, 0.20 + 0.18 * sin(drift * 6.28318));
    float sheen = exp(-3.5 * length((uv - sheenCenter) * vec2(1.2, 2.6)));
    col = mix(col, vec3(1.0), 0.14 * sheen);

    fragColor = vec4(col, 1.0);
}
