extends Node2D

@export var id: String
@export var dimension : Vector2i
@export var entrances_top : Vector2i
@export var entrances_left : Vector2i
@export var entrances_bottom : Vector2i
@export var entrances_right : Vector2i
@export var enemy_scenes: Array[PackedScene] = []
@export var is_peaceful_room : bool = false
@export var enemy_count : int

@onready var wall_tilemap : TileMapLayer = $WallTileLayer
@onready var floor_tilemap : TileMapLayer = $FloorTileLayer
@onready var tilemap_px : int = wall_tilemap.tile_set.tile_size.x

var room_state : int = 0 # 0: unvisited, 1: visited, 2: cleared
var door_config =  [true, true, true, true]
var enemy_counter : int = 0

const ENTRANCES = {
	0: "top",
	1: "left",
	2: "bottom",
	3: "right"
}

func _ready() -> void:
	if not door_config:
		door_config = [true, true, true, true]
	set_door_opened(true)

func rsignal_player_entered() -> void:
	room_state = 1
	set_door_opened(false)
	$EntranceDetector.queue_free()
	await get_tree().create_timer(2).timeout
	start_wave()

func clear_room() -> void:
	room_state = 2
	Main.show_title_ui("Clear!")
	set_door_opened(true)

func start_wave(spawn_delay: float = 0.1) -> void: # externally managed waves`
	var used_cells = floor_tilemap.get_used_cells()
	used_cells.shuffle()
	for i in range(enemy_count):
		var random_index = randi() % enemy_scenes.size()
		var enemy: EntityBase = enemy_scenes[random_index].instantiate()
		var local: Vector2 = used_cells[i] * tilemap_px
		enemy.global_position = local * global_scale + self.global_position
		enemy.connect("signal_death", rsignal_spawned_enemy_died)
		Main.control.get_child(3).add_child(enemy)
		await get_tree().create_timer(spawn_delay).timeout

func rsignal_spawned_enemy_died() -> void:
	enemy_counter += 1
	if enemy_counter == enemy_count:
		clear_room()

# /* ------------ Internals ----------- */

func set_door_opened(is_open: bool) -> void:
	for dir in range(4):
		var door_used = door_config[dir]
		if door_used:
			var entrance: Vector2i = get("entrances_" + ENTRANCES[dir])
			for i in range(2):
				var pos = Vector2i(
					entrance.x + (i if dir in [0, 2] else 0),
					entrance.y + (i if dir in [1, 3] else 0)
				)
				if is_open:
					wall_tilemap.set_cell(pos, 0, Vector2i(0,0))
				else:
					wall_tilemap.set_cell(pos, 1, Vector2i(0,0))
