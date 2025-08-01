extern float health_ratio;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 mask_color = Texel(texture, texture_coords);

    if (mask_color.a > 0.5) { // Transparent part of the mask
        float bar_start = 11.0 / 128.0;
        float bar_width = 106.0 / 128.0;
        float masked_x = bar_start + health_ratio * bar_width;

        if (texture_coords.x >= bar_start && texture_coords.x < masked_x) {
            return vec4(1.0, 0.0, 0.0, 1.0); // Solid red
        }
    }

    return vec4(0.0, 0.0, 0.0, 0.0);
}
