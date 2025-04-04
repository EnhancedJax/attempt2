shader_type canvas_item;

uniform float origin_x : hint_range(0.0, 1.0); // X coordinate of the origin (0 = left, 1 = right)
uniform float origin_y : hint_range(0.0, 1.0); // Y coordinate of the origin (0 = top, 1 = bottom)
uniform float progress : hint_range(0.0, 1.0); // Progress of the fade-out (0 = no fade, 1 = fully transparent)
uniform float fade_off : hint_range(0.01, 1.0); // How soft the circle's edge is
uniform int edge_fade_width : hint_range(1, 100) = 10; // Width of edge fade in pixels
uniform float edge_fade_off : hint_range(0.01, 1.0) = 0.5; // Softness of edge fade

void fragment() {
    // Get the UV coordinates of the current pixel
    vec2 uv = UV;

    // Convert edge fade width from pixels to UV space
    vec2 pixel_size = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
    float edge_width_uv = float(edge_fade_width) * max(pixel_size.x, pixel_size.y);

    // Calculate edge fade (distance from each edge)
    float edge_dist_left = uv.x;
    float edge_dist_right = 1.0 - uv.x;
    float edge_dist_top = uv.y;
    float edge_dist_bottom = 1.0 - uv.y;

    // Find the closest edge distance
    float edge_dist = min(min(edge_dist_left, edge_dist_right), min(edge_dist_top, edge_dist_bottom));

    // Calculate edge fade factor
    float edge_fade = smoothstep(0.0, edge_width_uv * edge_fade_off, edge_dist);

    // Calculate the distance from the origin to the current pixel
    float dist = distance(uv, vec2(origin_x, origin_y));

    // Normalize the distance by dividing it by the diagonal of the UV space (sqrt(2))
    dist /= sqrt(2.0);

    // Adjust the fade factor to account for fade_off at maximum progress
    float adjusted_progress = progress * (progress + fade_off);

    // Calculate the fade factor based on the adjusted progress and fade_off
    float fade = smoothstep(adjusted_progress - fade_off, adjusted_progress, dist);

    // Combine both fade effects
    float final_fade = min(fade, edge_fade);

    // Apply the fade to the alpha channel
    COLOR.a *= final_fade;
}