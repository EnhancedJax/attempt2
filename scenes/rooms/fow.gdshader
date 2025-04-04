shader_type canvas_item;

uniform float origin_x : hint_range(0.0, 1.0); // X coordinate of the origin (0 = left, 1 = right)
uniform float origin_y : hint_range(0.0, 1.0); // Y coordinate of the origin (0 = top, 1 = bottom)
uniform float progress : hint_range(0.0, 1.0); // Progress of the fade-out (0 = no fade, 1 = fully transparent)
uniform float fade_off : hint_range(0.01, 1.0); // How soft the circle's edge is

void fragment() {
    // Get the UV coordinates of the current pixel
    vec2 uv = UV;

    // Calculate the distance from the origin to the current pixel
    float dist = distance(uv, vec2(origin_x, origin_y));

    // Normalize the distance by dividing it by the diagonal of the UV space (sqrt(2))
    dist /= sqrt(2.0);

    // Adjust the fade factor to account for fade_off at maximum progress
    float adjusted_progress = progress * (progress + fade_off);

    // Calculate the fade factor based on the adjusted progress and fade_off
    float fade = smoothstep(adjusted_progress - fade_off, adjusted_progress, dist);

    // Apply the fade to the alpha channel
    COLOR.a *= fade;
}