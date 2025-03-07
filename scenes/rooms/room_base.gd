extends Node2D

signal signal_room_cleared()
signal signal_player_entered()

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

@onready var entrance_detector: Area2D = $EntranceDetector

var enemy_counter : int = 0

# values to be set by generator
var room_state : int = 0 # 0: unvisited, 1: visited, 2: cleared
var door_config =  [true, true, true, true]

const ENTRANCES = {
	0: "top",
	1: "left",
	2: "bottom",
	3: "right"
}

const ENTRANCE_WIDTH = 2  # tiles wide

func _ready() -> void:
	if not door_config:
		door_config = [true, true, true, true]
	set_door_opened(true)
	setup_entrance_detection()

func rsignal_player_entered() -> void:
	signal_player_entered.emit()
	if is_peaceful_room:
		room_state = 2
	elif room_state == 0:
		room_state = 1
		set_door_opened(false)
		# await get_tree().create_timer(1).timeout
		start_wave()
		# clear_room()

func clear_room() -> void:
	room_state = 2
	set_door_opened(true)
	signal_room_cleared.emit()

func start_wave(spawn_delay: float = 0.1) -> void: # externally managed waves`
	var used_cells = floor_tilemap.get_used_cells()
	used_cells.shuffle()
	for i in range(enemy_count):
		var random_index = randi() % enemy_scenes.size()
		var enemy: EntityBase = enemy_scenes[random_index].instantiate()
		var local: Vector2 = used_cells[i] * tilemap_px
		enemy.global_position = local * global_scale + self.global_position
		enemy.connect("signal_death", rsignal_spawned_enemy_died)
		Main.control.get_child(3).call_deferred("add_child", enemy)
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
					floor_tilemap.set_cell(pos, 0, Vector2i(0,0))
					wall_tilemap.set_cell(pos, 0, Vector2i(-1,-1))
				else:
					floor_tilemap.set_cell(pos, 1, Vector2i(0,0))
					wall_tilemap.set_cell(pos, 1, Vector2i(-1,-1))

func setup_entrance_detection() -> void:
	for dir in range(4):
		if not door_config[dir]:
			continue
			
		var shape = RectangleShape2D.new()
		var collision = CollisionShape2D.new()
		collision.shape = shape
		
		# Get entrance position based on direction
		var entrance: Vector2i = get("entrances_" + ENTRANCES[dir])
		var pos = Vector2(entrance) * tilemap_px
		
		# Configure shape size and position based on direction
		if dir in [0, 2]:  # top or bottom
			shape.size = Vector2(ENTRANCE_WIDTH * tilemap_px, tilemap_px)
			pos.x = (pos.x + (ENTRANCE_WIDTH * tilemap_px) / 2)
			pos.y = pos.y + (tilemap_px / 2)
			# Adjust top and bottom positions
			if dir == 0:  # top
				pos.y += tilemap_px
			else:  # bottom
				pos.y -= tilemap_px
		else:  # left or right
			shape.size = Vector2(tilemap_px, ENTRANCE_WIDTH * tilemap_px)
			pos.x = pos.x + (tilemap_px / 2)
			pos.y = (pos.y + (ENTRANCE_WIDTH * tilemap_px) / 2)
			# Adjust left and right positions
			if dir == 1:  # left
				pos.x += tilemap_px
			else:  # right
				pos.x -= tilemap_px
			
		collision.position = pos
		entrance_detector.add_child(collision)
