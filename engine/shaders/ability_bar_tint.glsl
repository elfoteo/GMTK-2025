extern float mana_ratio;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    // Sample the mask (grayscale gradient)
    vec4 mcol = Texel(texture, uv);
    float maskVal = mcol.r;   // between 0.0 (black) and 1.0 (white)

    // Compute priority threshold:
    // when mana=1 → thresh=0 → everything (maskVal≥0) draws
    // when mana=0 → thresh=1 → nothing (maskVal<1) draws
    float thresh = 1.0 - clamp(mana_ratio, 0.0, 1.0);

    // Only draw if we're inside the mask and above the threshold
    if (mcol.a > 0.5 && mana_ratio > 0.0 && maskVal >= thresh) {
        // Soft blue fill
        return vec4(0.2, 0.6, 1.0, 1.0);
    }

    // Else fully transparent
    return vec4(0.0);
}

