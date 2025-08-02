extern float health_ratio;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    // Sample the mask (grayscale + alpha)
    vec4 mcol = Texel(texture, uv);
    float maskAlpha = mcol.a;
    float maskVal   = mcol.r;    // R=G=B for a grayscale gradient

    // Only operate inside the shape of your mask
    if (maskAlpha > 0.5) {
        // Compute threshold: when health=1 → thresh=0 → all maskVal≥0 pass
        // when health=0 → thresh=1 → no maskVal<1 pass (empty)
        float thresh = 1.0 - clamp(health_ratio, 0.0, 1.0);

        // If this pixel’s grayscale ≥ thresh, it’s “filled”
        if (maskVal >= thresh) {
            return vec4(1.0, 0.0, 0.0, 1.0);
        }
    }

    // Otherwise transparent
    return vec4(0.0);
}

