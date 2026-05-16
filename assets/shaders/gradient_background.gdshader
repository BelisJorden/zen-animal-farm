shader_type canvas_item;

uniform vec4 color_top    : source_color = vec4(0.769, 0.682, 0.867, 1.0);
uniform vec4 color_mid    : source_color = vec4(0.855, 0.759, 0.795, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.941, 0.835, 0.722, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float t = UV.y;
	vec4 grad = (t < 0.5)
		? mix(color_top, color_mid, t * 2.0)
		: mix(color_mid, color_bottom, (t - 0.5) * 2.0);

	float dist = length(UV - vec2(0.5));
	float vignette = smoothstep(0.4, 0.72, dist) * vignette_strength;
	grad.rgb = mix(grad.rgb, vec3(0.0), vignette);

	COLOR = grad;
}
