shader_type canvas_item;

uniform vec4 og_color_1 : source_color = vec4(0.675, 0.0, 0.776, 1.0); // #AC00C6
uniform vec4 hand_color_1 : source_color = vec4(0.914, 0.678, 0.490, 1.0); // #E9AD7D
uniform vec4 og_color_2 : source_color = vec4(0.87, 0.0, 1.0, 1.0);  // #DF00FF
uniform vec4 hand_color_2 : source_color = vec4(0.73,0.43,0.34, 1.0); // #BB6D53

void fragment() {
	vec4 curr_color = texture(TEXTURE, UV);

	uvec4 uint_curr_color = uvec4(round(curr_color * 255.0));
	uvec4 uint_og_color_1 = uvec4(round(og_color_1 * 255.0));
	uvec4 uint_og_color_2 = uvec4(round(og_color_2 * 255.0));

	if (uint_curr_color == uint_og_color_1) {
		COLOR = hand_color_1;
	}
	else if (uint_curr_color == uint_og_color_2) {
		COLOR = hand_color_2;
	}
	else {
		COLOR = curr_color;
	}
}