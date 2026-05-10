shader_type canvas_item;

uniform vec4 color_top    : source_color = vec4(0.769, 0.682, 0.867, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.941, 0.835, 0.722, 1.0);

void fragment() {
	COLOR = mix(color_top, color_bottom, UV.y);
}
