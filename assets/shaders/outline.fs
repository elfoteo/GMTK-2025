extern float outline_thickness;
extern vec4 outline_color;

const int SAMPLE_COUNT = 16;

vec2[16] offsets = vec2[](
    vec2(1, 0), vec2(-1, 0), vec2(0, 1), vec2(0, -1),
    vec2(1, 1), vec2(-1, 1), vec2(1, -1), vec2(-1, -1),
    vec2(2, 0), vec2(-2, 0), vec2(0, 2), vec2(0, -2),
    vec2(2, 2), vec2(-2, 2), vec2(2, -2), vec2(-2, -2)
);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 base = Texel(texture, texture_coords);
    if (base.a > 0.0) {
        return base;
    }

    float alpha = 0.0;
    for (int i = 0; i < SAMPLE_COUNT; i++) {
        vec2 offset_uv = texture_coords + (offsets[i] * outline_thickness / love_ScreenSize.xy);
        alpha = max(alpha, Texel(texture, offset_uv).a);
    }

    return vec4(outline_color.rgb, outline_color.a * alpha);
}

