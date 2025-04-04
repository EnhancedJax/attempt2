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
@export var is_peaceful_room : bool = false
@export var waves_data : Waves
@export var door_vertical : PackedScene
@export var door_horizontal : PackedScene
@export var enemy_spawner : PackedScene

@export var reward_coins_min : int = 1
@export var reward_coins_max : int = 3

@export var wall_tilemap : TileMapLayer
@export var floor_tilemap : TileMapLayer
@onready var tilemap_px : int = wall_tilemap.tile_set.tile_size.x

@export var fow_canvas : CanvasLayer
@export var fow : Sprite2D
@export var should_fow: bool = true

#region Customizable constants
## Amount of tiles away from the player that the enemy must not be randomly spawned at
const spawn_player_margin : int = 3
## Amount of tiles away from walls that the enemy must not be randomly spawned at
const spawn_room_margin : int = 1

const ENTRANCE_WIDTH: int = 2  # tiles wide. Changing this requires a refactor of the whole project!
const DOOR_PADDING_FROM_ENTRANCE: float = 1.5

const entrance_detector_scene = preload("res://scenes/rooms/entrance_detector.tscn")
const coin_scene = preload("res://scenes/coin/coin_spawner.tscn")

#region Internals
var _enemy_remaining: int = 0
var _room_enemies : Array[EntityBase] = []
var _current_wave_index : int = 0
var _total_enemy_in_waves : int = 0

var _boss_counter : int = 0
var total_bosses : int = 0
var _room_bosses : Array[EntityBase] = []

var _shuffled_used_cells : Array[Vector2i] = []
var _current_doors: Array[Door] = []

#region Values set by generator
var room_state : int = 0 # 0: unvisited, 1: visited, 2: cleared
var door_config : Array[bool] =  [true, true, true, true]
var room_data : Dungen.Room = null

const ENTRANCES : Dictionary[int, String] = {
	0: "top",
	1: "left",
	2: "bottom",
	3: "right"
}

#region FOW
var fow_is_animating := false
var fow_animation_time := 0.0
var fow_animation_duration := 1.0
var fow_entrance_point := Vector2.ZERO
var fow_image: Image
var fow_texture: ImageTexture
const FOW_PADDING: int = 0 # tiles wide

func _ready() -> void:
	randomize()
	if not door_config:
		door_config = [true, true, true, true]
	_setup_doors_and_entrances()
	_setup_entrance_detection()
	_shuffled_used_cells = floor_tilemap.get_used_cells()
	_shuffled_used_cells.shuffle()
	_calculate_total_enemies()
	if should_fow:
		_setup_fog_of_war()

func _process(delta: float) -> void:
	if fow_is_animating:
		fow_animation_time += delta
		var progress = fow_animation_time / fow_animation_duration
		if progress >= 1.0:
			fow_is_animating = false
			progress = 1.0
		_update_fow_animation(progress)

func _calculate_total_enemies() -> void:
	if not waves_data or waves_data.waves.is_empty() or Main.IS_DEBUG_MODE:
		_total_enemy_in_waves = 0
		total_bosses = 0
		return
	for wave in waves_data.waves:
		for enemy in wave.wave_enemies:
			_total_enemy_in_waves += enemy.spawn_count
			if enemy.enemy_is_boss:
				total_bosses += enemy.spawn_count

func _on_player_entered(entrance_index: int) -> void:
	print("Player entered through entrance: ", entrance_index)
	signal_player_entered.emit()
	if should_fow and room_state == 0:
		_start_fow_animation(entrance_index)
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
	handle_clear_room_rewards()

func handle_clear_room_rewards():
	# Spawn random number of coins at each enemy's position
	for enemy in _room_enemies:	
		var coin_count = randi_range(reward_coins_min, reward_coins_max)
		var coin = coin_scene.instantiate()
		coin.count = coin_count
		Main.spawn_node(coin, enemy.global_position, 3)

func start_wave() -> void:
	if not waves_data or waves_data.waves.is_empty() or Main.IS_DEBUG_MODE:
		clear_room()
		return
		
	var current_wave: Wave = waves_data.waves[_current_wave_index]
	_enemy_remaining = 0    # initialize enemy count for current wave
	for enemy_props in current_wave.wave_enemies:
		_enemy_remaining += enemy_props.spawn_count
	for enemy_props in current_wave.wave_enemies:
		for i in range(enemy_props.spawn_count):
			var enemy: EntityBase = enemy_props.enemy.instantiate()
			
			if enemy_props.enemy_is_boss:
				enemy.connect("signal_death", _on_boss_died)
				_room_bosses.append(enemy)
				
				if enemy_props.splash_scene:
					# Show boss splash screen
					var splash = enemy_props.splash_scene.instantiate()
					get_tree().root.add_child(splash)
					splash.play()
					Main.control.process_mode = Node.PROCESS_MODE_DISABLED
					await splash.signal_splash_finished
					Main.control.process_mode = Node.PROCESS_MODE_INHERIT
				
				# Play boss music
				MusicManager.play("bgm", enemy_props.boss_bgm, 1.0, true)
			
			enemy.connect("signal_death", _on_spawned_enemy_died)
			
			var spawn_position: Vector2
			if enemy_props.spawn_at_center:
				spawn_position = _get_room_center() + enemy_props.spawn_center_offset
			else:
				spawn_position = _pick_random_spawn_point()
			
			var new_enemy_spawner : EnemySpawner = enemy_spawner.instantiate()
			new_enemy_spawner.node = enemy
			Main.spawn_node(new_enemy_spawner, spawn_position, 3)
			_room_enemies.append(enemy)
			
			if enemy_props.spawn_delay > 0:
				await get_tree().create_timer(enemy_props.spawn_delay).timeout

func _on_spawned_enemy_died() -> void:
	_enemy_remaining -= 1
	if _enemy_remaining <= 0:
		if _current_wave_index < waves_data.waves.size() - 1:
			_current_wave_index += 1
			start_wave()
		else:
			clear_room()

func _on_boss_died() -> void:
	_boss_counter += 1
	if _boss_counter == total_bosses:
		MusicManager.play("bgm", "bgm", 1.0, true)

func enable() -> void:
	self.visible = true
	self.process_mode = Node2D.PROCESS_MODE_INHERIT
	self.wall_tilemap.enabled = true
	self.floor_tilemap.enabled = true

func disable() -> void:
	self.visible = false
	self.process_mode = Node2D.PROCESS_MODE_DISABLED
	self.wall_tilemap.enabled = false
	self.floor_tilemap.enabled = false

# /* ------------ Internals ----------- */

func _pick_random_spawn_point() -> Vector2:
	var valid_position_found := false
	var local := Vector2.ZERO
	var attempts := 0
	const MAX_ATTEMPTS := 100
	
	while not valid_position_found and attempts < MAX_ATTEMPTS:
		var random_index := randi() % _shuffled_used_cells.size()
		local = _shuffled_used_cells[random_index] * tilemap_px
		var global_pos := local * global_scale + global_position
		
		# Check distance from player
		var player_distance := (global_pos - Main.player.global_position).length() / tilemap_px
		if player_distance < spawn_player_margin:
			attempts += 1
			continue
			
		# Check distance from walls
		if _is_near_wall(_shuffled_used_cells[random_index]):
			attempts += 1
			continue
			
		valid_position_found = true
	
	# If no valid position found after max attempts, use the last tried position
	return local * global_scale + global_position

func _is_near_wall(cell_pos: Vector2i) -> bool:
	# Check surrounding cells in a square pattern
	for x in range(-spawn_room_margin, spawn_room_margin + 1):
		for y in range(-spawn_room_margin, spawn_room_margin + 1):
			var check_pos := cell_pos + Vector2i(x, y)
			# If any surrounding cell is a wall or outside the floor, position is invalid
			if not floor_tilemap.get_cell_source_id(check_pos) == 0:
				return true
	return false

func _get_room_center() -> Vector2:
	var local: Vector2 = Vector2(dimension.x / 2, dimension.y / 2) * tilemap_px
	return local * global_scale + self.global_position

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
			_current_doors.append(door_instance)

func _open_doors() -> void:
	for d in _current_doors:
		d.call_open_door()

func _close_doors() -> void:
	for d in _current_doors:
		d.call_lock_door()
		d.call_close_door()

func _setup_entrance_detection() -> void:
	for dir in range(4):
		if not door_config[dir]:
			continue
			
		var detector = entrance_detector_scene.instantiate()
		detector.connect('signal_player_entered', _on_player_entered.bind(dir))
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
