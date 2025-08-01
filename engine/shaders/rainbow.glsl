extern number time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    if (pixel.a > 0.0) {
        float rainbow = (-screen_coords.x - screen_coords.y) / 75.0 + time*0.75;
        pixel.r = (sin(rainbow * 2.0) + 1.0) / 2.0;
        pixel.g = (sin(rainbow * 2.0 + 2.0 * 3.14159 / 3.0) + 1.0) / 2.0;
        pixel.b = (sin(rainbow * 2.0 + 4.0 * 3.14159 / 3.0) + 1.0) / 2.0;
    }
    return pixel;
}
