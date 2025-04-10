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
@export var fow_texture : Sprite2D
@export var fow_animation_player : AnimationPlayer
@export var should_fow: bool = true

#region Customizable constants
## Amount of tiles away from the player that the enemy must not be randomly spawned at
const spawn_player_margin : int = 3
## Amount of tiles away from walls that the enemy must not be randomly spawned at
const spawn_room_margin : int = 1

const ENTRANCE_WIDTH: int = 2  # tiles wide. Changing this requires a refactor of the whole project!
const door_entrance_distance: float = 1.5

var fow_color: String = "#191919"

const coin_scene = preload("res://scenes/coin/coin_spawner.tscn")
const entrance_detector_scene = preload("res://scenes/rooms/entrance_detector.tscn")

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
var _cached_wall_cells : Array[Vector2i] = []

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

func _ready() -> void:
	randomize()
	if not door_config:
		door_config = [true, true, true, true]
	_shuffled_used_cells = floor_tilemap.get_used_cells()
	_shuffled_used_cells.shuffle()
	_cached_wall_cells = wall_tilemap.get_used_cells()

	_setup_fog_of_war(_cached_wall_cells)
	_setup_entrance_detection()
	_calculate_total_enemies()
	_setup_doors_and_entrances()

	Main.signal_debug_mode_changed.connect(_on_debug_mode_changed)
	_on_debug_mode_changed()

func _on_debug_mode_changed() -> void:
	var setup_again = true
	if fow_color == "#191919" and not Main.IS_DEBUG_MODE:
		setup_again = false
	print(setup_again)
	if Main.IS_DEBUG_MODE:
		fow_color = "#FF0000"
	else:
		fow_color = "#191919"
	if setup_again:
		_setup_fog_of_war(_cached_wall_cells)

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
	_play_fow_animation(entrance_index)
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
	self.fow_canvas.visible = should_fow
	self.fow_texture.visible = should_fow

func disable() -> void:
	self.visible = false
	self.process_mode = Node2D.PROCESS_MODE_DISABLED
	self.wall_tilemap.enabled = false
	self.floor_tilemap.enabled = false
	self.fow_canvas.visible = false
	self.fow_texture.visible = false

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
					door_pos.y -= tilemap_px * door_entrance_distance
				1: # left
					door_pos.x -= tilemap_px * door_entrance_distance
				2: # bottom
					door_pos.y += tilemap_px * door_entrance_distance
				3: # right
					door_pos.x += tilemap_px * door_entrance_distance
			
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

func _setup_fog_of_war(wall_cells: Array[Vector2i]) -> void:
	fow_canvas.visible = should_fow
	if should_fow:
		var min_x: int = dimension.x
		var min_y: int = dimension.y
		var max_x: int = 0
		var max_y: int = 0
		
		# Find the bounds of the room
		for cell in wall_cells:
			min_x = min(min_x, cell.x)
			min_y = min(min_y, cell.y)
			max_x = max(max_x, cell.x)
			max_y = max(max_y, cell.y)
		
		var room_width: int = (max_x - min_x + 1) * tilemap_px
		var room_height: int = (max_y - min_y + 1) * tilemap_px
		
		# Position the fog texture
		fow_texture.position = self.global_position + Vector2(min_x, min_y) * tilemap_px
		fow_texture.position.y -= 0.5 * tilemap_px
		room_height += 0.5 * tilemap_px
		
		# Create the fog image
		var fow_image: Image = Image.create(room_width, room_height, false, Image.FORMAT_RGBA8)
		fow_image.fill(Color(0, 0, 0, 0))
		
		var fog_color: Color = Color.html(fow_color)
		var room_mask: Array[Array] = _create_room_mask(wall_cells, min_x, min_y)
		
		# Batch operations to reduce individual pixel operations
		for y in range(0, room_height, 4):
			for x in range(0, room_width, 4):
				var tile_x: float = x / tilemap_px
				var tile_y: float = y / tilemap_px
				
				if _is_inside_room(tile_x, tile_y, room_mask):
					# Fill a 4x4 block for better performance
					for dy in range(min(4, room_height - y)):
						for dx in range(min(4, room_width - x)):
							fow_image.set_pixel(x + dx, y + dy, fog_color)
		
		fow_texture.texture = ImageTexture.create_from_image(fow_image)
		fow_texture.material.set_shader_parameter("progress", 0.0)

func _play_fow_animation(entrance_index: int) -> void:
	if should_fow and room_state == 0:
		var entrance: Vector2i = get("entrances_" + ENTRANCES[entrance_index])
		var entrance_pos: Vector2 = Vector2(entrance) * tilemap_px
		
		var texture_size: Vector2 = fow_texture.texture.get_size()
		
		var local_entrance_pos: Vector2 = entrance_pos - (fow_texture.position - self.global_position)
		var origin_x: float = local_entrance_pos.x / texture_size.x
		var origin_y: float = local_entrance_pos.y / texture_size.y
		
		fow_texture.material.set_shader_parameter("origin_x", origin_x)
		fow_texture.material.set_shader_parameter("origin_y", origin_y)
		fow_animation_player.play("fade_out")

func _create_room_mask(wall_cells: Array[Vector2i], min_x: int, min_y: int) -> Array[Array]:
	var max_x: int = 0
	var max_y: int = 0
	
	# Find maximum bounds
	for cell in wall_cells:
		max_x = max(max_x, cell.x - min_x)
		max_y = max(max_y, cell.y - min_y)
	
	var grid_width: int = max_x + 3
	var grid_height: int = max_y + 3
	var grid: Array[Array] = []
	
	# Pre-allocate the grid with proper size
	grid.resize(grid_height)
	for y in range(grid_height):
		var row: Array[int] = []
		row.resize(grid_width)
		for x in range(grid_width):
			row[x] = 0
		grid[y] = row
	
	# Mark wall cells
	for cell in wall_cells:
		var grid_x: int = cell.x - min_x + 1
		var grid_y: int = cell.y - min_y + 1
		
		if grid_x >= 0 and grid_x < grid_width and grid_y >= 0 and grid_y < grid_height:
			grid[grid_y][grid_x] = 1
	
	# Fill outside areas
	_flood_fill_outside(grid, grid_width, grid_height)
	
	# Mark inside areas
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x] == 0:
				grid[y][x] = 3
	
	return grid

func _flood_fill_outside(grid: Array[Array], width: int, height: int) -> void:
	var queue: Array[Vector2i] = []
	queue.resize(2 * (width + height)) # Pre-allocate for better performance
	
	# Add border cells to queue`
	for x in range(width):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	
	for y in range(1, height - 1): # Skip corners already added
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))
	
	# Directions for flood fill (right, left, down, up)
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		var x: int = pos.x
		var y: int = pos.y
		
		if x < 0 or x >= width or y < 0 or y >= height or grid[y][x] != 0:
			continue
		
		grid[y][x] = 2
		
		# Use pre-defined directions
		for dir in directions:
			queue.append(Vector2i(x + dir.x, y + dir.y))

func _is_inside_room(tile_x: float, tile_y: float, room_mask: Array[Array]) -> bool:
	var grid_x: int = int(tile_x) + 1
	var grid_y: int = int(tile_y) + 1
	
	# Boundary check
	if grid_y < 0 or grid_y >= room_mask.size():
		return false
	
	var row: Array = room_mask[grid_y]
	if grid_x < 0 or grid_x >= row.size():
		return false
	
	# Check if the cell is part of the room (3) or a wall (1)
	return row[grid_x] == 3 or row[grid_x] == 1
