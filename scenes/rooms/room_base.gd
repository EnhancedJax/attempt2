class_name RoomBase
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
@export var door_vertical : PackedScene
@export var door_horizontal : PackedScene
@export var should_fow: bool = true

@onready var wall_tilemap : TileMapLayer = $WallTileLayer
@onready var floor_tilemap : TileMapLayer = $FloorTileLayer
@onready var tilemap_px : int = wall_tilemap.tile_set.tile_size.x

@onready var fow_canvas : CanvasLayer = $FogOfWar
@onready var fow : Sprite2D = $FogOfWar/ColorRect

const entrance_detector_scene = preload("res://scenes/rooms/entrance_detector.tscn")
const coin_scene = preload("res://scenes/coin/coin_spawner.tscn")
var enemy_counter : int = 0

# values to be set by generator
var room_state : int = 0 # 0: unvisited, 1: visited, 2: cleared
var door_config : Array[bool] =  [true, true, true, true]

const ENTRANCES : Dictionary[int, String] = {
	0: "top",
	1: "left",
	2: "bottom",
	3: "right"
}

const ENTRANCE_WIDTH: int = 2  # tiles wide
const DOOR_PADDING_FROM_ENTRANCE: int = 1

const FOW_PADDING: int = 0 # tiles wide

var current_doors: Array[Door] = []

# FOW Animation
var fow_is_animating := false
var fow_animation_time := 0.0
var fow_animation_duration := 1.0
var fow_entrance_point := Vector2.ZERO
var fow_image: Image
var fow_texture: ImageTexture

func _ready() -> void:
	if not door_config:
		door_config = [true, true, true, true]
	_setup_doors_and_entrances()
	_setup_entrance_detection()
	# if should_fow:
	# 	_setup_fog_of_war()

func _process(delta: float) -> void:
	if fow_is_animating:
		fow_animation_time += delta
		var progress = fow_animation_time / fow_animation_duration
		if progress >= 1.0:
			fow_is_animating = false
			progress = 1.0
		_update_fow_animation(progress)

func rsignal_player_entered(entrance_index: int) -> void:
	print("Player entered through entrance: ", entrance_index)
	signal_player_entered.emit()
	# if should_fow and room_state == 0:
	# 	_start_fow_animation(entrance_index)
	if is_peaceful_room:
		room_state = 2
	elif room_state == 0:
		room_state = 1
		_close_doors()
		start_wave()

func clear_room() -> void:
	room_state = 2
	_open_doors()
	signal_room_cleared.emit()

	# spawn coins at the center of the room
	var coin = coin_scene.instantiate()
	coin.count = 10
	var local: Vector2 = Vector2(dimension.x / 2, dimension.y / 2) * tilemap_px
	coin.global_position = local * global_scale + self.global_position
	Main.control.get_child(3).call_deferred("add_child", coin)

func start_wave(spawn_delay: float = 0.1) -> void: # externally managed waves`
	var used_cells = floor_tilemap.get_used_cells()
	used_cells.shuffle()
	if enemy_count == 0:
		clear_room()
		return
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

func _setup_doors_and_entrances() -> void:
	for dir in range(4):
		var door_used = door_config[dir]
		if door_used:
			var entrance: Vector2i = get("entrances_" + ENTRANCES[dir])

			# remove wall tile
			for i in range(2):
				var pos = Vector2i(
					entrance.x + (i if dir in [0, 2] else 0),
					entrance.y + (i if dir in [1, 3] else 0)
				)
				floor_tilemap.set_cell(pos, 0, Vector2i(0,0))
				wall_tilemap.set_cell(pos, 0, Vector2i(-1,-1))
			
			# spawn doors if not peaceful
			if is_peaceful_room:
				continue
			# Choose door type based on direction
			var door_scene = door_horizontal if dir in [1, 3] else door_vertical
			var door_instance = door_scene.instantiate()
			add_child(door_instance)
			
			# Calculate door position (2 tiles back from entrance)
			var door_pos = Vector2(entrance) * tilemap_px
			match dir:
				0: # top
					door_pos.y -= tilemap_px * DOOR_PADDING_FROM_ENTRANCE
				1: # left
					door_pos.x -= tilemap_px * DOOR_PADDING_FROM_ENTRANCE
				2: # bottom
					door_pos.y += tilemap_px * DOOR_PADDING_FROM_ENTRANCE
				3: # right
					door_pos.x += tilemap_px * DOOR_PADDING_FROM_ENTRANCE
			
			door_instance.position = door_pos
			current_doors.append(door_instance)

func _open_doors() -> void:
	for d in current_doors:
		d.call_open_door()

func _close_doors() -> void:
	for d in current_doors:
		d.call_lock_door()
		d.call_close_door()

func _setup_entrance_detection() -> void:
	for dir in range(4):
		if not door_config[dir]:
			continue
			
		var detector = entrance_detector_scene.instantiate()
		detector.connect('signal_player_entered', rsignal_player_entered.bind(dir))
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
		detector.add_child(collision)
		self.add_child(detector)

func _setup_fog_of_war() -> void:
	# note: all fow positions relative to the origin of world, as canvas layers are positioned at origin.
	var padded_size = Vector2(
		(dimension.x + FOW_PADDING * 2) * tilemap_px,
		(dimension.y + FOW_PADDING * 2) * tilemap_px
	)
	fow.position = self.global_position - Vector2(FOW_PADDING * tilemap_px, FOW_PADDING * tilemap_px)
	
	# Create the fog image
	fow_image = Image.create(padded_size.x, padded_size.y, false, Image.FORMAT_RGBA8)
	fow_image.fill(Color.html("#191919"))
	fow_texture = ImageTexture.create_from_image(fow_image)
	fow.texture = fow_texture

func _start_fow_animation(entrance_index: int) -> void:
	fow_is_animating = true
	fow_animation_time = 0.0
	
	# Calculate entrance point based on entrance_index
	var entrance: Vector2i = get("entrances_" + ENTRANCES[entrance_index])
	fow_entrance_point = Vector2(entrance) * tilemap_px + self.global_position

func _update_fow_animation(progress: float) -> void:
	if not fow_image or not fow_texture:
		return
		
	var center = fow_entrance_point - fow.position
	var max_dimension = max(fow_image.get_width(), fow_image.get_height())
	var radius = max_dimension * progress
	var gradient_size = 100.0  # Size of the gradient border in pixels
	
	# Create circular reveal effect with gradient
	for y in range(fow_image.get_height()):
		for x in range(fow_image.get_width()):
			var dist = Vector2(x, y).distance_to(center)
			var alpha = 1.0
			if dist < radius - gradient_size:
				alpha = 0.0
			elif dist < radius:
				alpha = (dist - (radius - gradient_size)) / gradient_size
			fow_image.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	fow_texture.update(fow_image)
