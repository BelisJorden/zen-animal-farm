extends StaticBody3D

const GRASS_COLOR  := Color(0.38, 0.68, 0.28)
const SOIL_COLOR   := Color(0.46, 0.30, 0.16)
const LILA_SOFT    := Color(0.58, 0.44, 0.78, 0.42)
const LILA_STRONG  := Color(0.58, 0.44, 0.78, 0.82)

var grid_pos: Vector2i = Vector2i.ZERO
var is_occupied: bool = false

@onready var _mesh:      MeshInstance3D = $Mesh
@onready var _highlight: MeshInstance3D = $Highlight


func _ready() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
uniform vec4 grass_color : source_color;
uniform vec4 soil_color  : source_color;
varying float is_top;
void vertex() {
	vec3 world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	is_top = step(0.85, world_n.y);
}
void fragment() {
	ALBEDO    = mix(soil_color.rgb, grass_color.rgb, is_top);
	ROUGHNESS = 0.92;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("grass_color", GRASS_COLOR)
	mat.set_shader_parameter("soil_color",  SOIL_COLOR)
	_mesh.material_override = mat

	var hi := StandardMaterial3D.new()
	hi.albedo_color = LILA_SOFT
	hi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hi.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight.material_override = hi


func set_highlighted(on: bool, strong: bool = false) -> void:
	_highlight.visible = on
	if on:
		(_highlight.material_override as StandardMaterial3D).albedo_color = \
			LILA_STRONG if strong else LILA_SOFT
