extends Node3D

const GRID_SIZE  := 5
const TILE_SIZE  := 0.6
const TILE_SCENE := preload("res://scenes/world/Tile.tscn")

var _tiles: Dictionary = {}  # Vector2i → StaticBody3D (Tile)


func _ready() -> void:
	_generate()


func _generate() -> void:
	var half := GRID_SIZE / 2
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile: StaticBody3D = TILE_SCENE.instantiate()
			add_child(tile)
			var gp := Vector2i(col, row)
			tile.grid_pos = gp
			tile.position = Vector3(
				(col - half) * TILE_SIZE,
				0.0,
				(row - half) * TILE_SIZE
			)
			_tiles[gp] = tile


func get_tile(gp: Vector2i) -> StaticBody3D:
	return _tiles.get(gp)


func all_tiles() -> Array:
	return _tiles.values()


func world_pos_of(gp: Vector2i) -> Vector3:
	var half := GRID_SIZE / 2
	return Vector3((gp.x - half) * TILE_SIZE, 0.0, (gp.y - half) * TILE_SIZE)


func highlight_free(on: bool) -> void:
	for tile in _tiles.values():
		if not tile.is_occupied:
			tile.set_highlighted(on)


func clear_highlights() -> void:
	for tile in _tiles.values():
		tile.set_highlighted(false)
