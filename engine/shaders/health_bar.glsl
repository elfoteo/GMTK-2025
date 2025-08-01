extern float health_ratio;
extern sampler2D bar_texture;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 mask_color = Texel(texture, texture_coords);
    vec4 bar_color = Texel(bar_texture, texture_coords);

    if (mask_color.a > 0.5) { // Frame part of the mask
        return mask_color;
    }

    // Bar part of the mask (transparent area)
    float bar_start = 11.0 / 128.0;
    float bar_width = 106.0 / 128.0;
    float masked_x = bar_start + health_ratio * bar_width;

    if (texture_coords.x >= bar_start && texture_coords.x < masked_x) {
        return bar_color;
    }

    return vec4(0.0, 0.0, 0.0, 0.0); // Empty part is transparent
}
