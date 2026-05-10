shader_type sky;

uniform vec4 color_top    : source_color = vec4(0.761, 0.784, 0.847, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.929, 0.878, 0.800, 1.0);
uniform float viewport_height : hint_range(1.0, 4096.0) = 960.0;

void sky() {
	float t  = clamp(FRAGCOORD.y / viewport_height, 0.0, 1.0);
	COLOR    = mix(color_top.rgb, color_bottom.rgb, t);
	ALPHA    = 1.0;
}
