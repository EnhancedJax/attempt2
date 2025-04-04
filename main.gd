extends Node2D

var player : Player
var camera : PlayerCamera
var hud : HUD
var interaction_label : InteractionLabel
var control : Control

var player_autoaim_target : Node2D = null
var player_autoaim_previous_target : Node2D = null
var interactions: Array[Interaction]
var is_paused: bool = false
const floor_item = preload("res://scenes/interactions/floor_item/floor_item.tscn")
const ENEMY_SWITCH_MINIMUM_DISTANCE = 64
var player_room_at: RoomBase = null

var coins = 0
var IS_DEBUG_MODE : bool = false

signal signal_player_equipped_weapon(node: Node2D)
signal signal_player_landed_hit()
signal signal_interaction_changed(interaction: Interaction)
signal signal_player_entered_room(room: RoomBase)
signal signal_player_room_changed(room: RoomBase)
signal signal_player_room_cleared()

signal signal_r_control()
signal signal_r_hud()

signal signal_reactive_setting_updated(setting: ggsSetting, value: Variant)

func _process(_delta: float) -> void:
	_update_player_autoaim_target()
	if Input.is_action_just_pressed("menu"):
		Router.navigate('pause')
	if Input.is_action_just_pressed("dev"):
		var scene = floor_item.instantiate()
		var weapons = Lookup.get_droppable_items()
		scene.item_id = weapons[randi() % weapons.size()]
		scene.global_position = player.global_position 
		control.get_child(3).add_child(scene)

# /* ------------ Registers ----------- */

func register_hud(h : HUD) -> void:
	hud = h
	update_health_ui()
	signal_r_hud.emit()

func register_player(p : Player) -> void:
	player = p

func register_camera(c : PlayerCamera) -> void:
	camera = c

func register_interaction_label(l : InteractionLabel) -> void:
	interaction_label = l

func register_control(c : Control) -> void:
	control = c
	signal_r_control.emit()

func register_boss(boss: BossBase) -> void:
	hud.register_boss(boss)

func deregister_boss(boss: BossBase) -> void:
	camera.focus_boss(boss)
	hud.deregister_boss(boss)
	var bullets = get_tree().get_nodes_in_group("bullet")
	for b in bullets:
		b.handle_hit()

func register_interaction(i: Interaction):
	print('Interaction register', i)
	interactions.push_front(i)
	interaction_label.display(i.label, i.label_position)
	signal_interaction_changed.emit(i)

func reregister_interaction(i: Interaction):
	print('Interaction reregister', i)
	interaction_label.remove()
	signal_interaction_changed.emit(i)

func deregister_interaction(i: Interaction):
	print('Interaction deregister', i)
	var index = 0
	for interaction in interactions:
		if interaction == i:
			break
		index += 1
	interactions.pop_at(index)
	if interactions.size() > 0:
		signal_interaction_changed.emit(interactions[0])
		interaction_label.display(interactions[0].label, interactions[0].label_position)
	else:
		interaction_label.visible = false
		signal_interaction_changed.emit(null)

# /* ------------- Methods ------------ */

func update_health_ui() -> void:
	if player:
		var health_component = player._health
		hud.update_health(health_component.health, health_component.MAX_HEALTH)

func update_equipped_weapon_ui(weapon: Lookup.WeaponType) -> void:
	if player and weapon and hud:
		hud.update_equipped_weapon(weapon)

func show_title_ui(str: String):
	hud.show_title(str)

func update_coins(amount: int) -> void:
	coins += amount
	hud.update_coins(coins)

func update_shield_ui(is_active: bool) -> void:
	hud.update_shield(is_active)

func update_ammo_ui(count: int, max: int) -> void:
	if hud:
		hud.update_ammo(count, max)

func _on_player_room_entered(id: int, room: RoomBase) -> void:
	if room != player_room_at:
		signal_player_room_changed.emit(room)
	player_room_at = room
	signal_player_entered_room.emit(room)
	if hud:
		hud.update_minimap(id)

func _on_player_room_cleared() -> void:
	signal_player_room_cleared.emit()

# /* ------------- Helpers ------------ */

func impact_frame(duration: float):
	Engine.time_scale = 0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1

func spawn_node(node : Node, position_global : Vector2, layer: int = 0) -> void:
	node.global_position = position_global
	control.get_child(layer).add_child(node)
# /* ------------ Internals ------------ */

func _toggle_pause() -> void:
	is_paused = !is_paused
	control.process_mode = Node.PROCESS_MODE_DISABLED if is_paused else PROCESS_MODE_INHERIT

func _update_player_autoaim_target() -> void:
	if player:
		var pos = player.global_position
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_enemy: Node2D = null
		var closest_distance := INF
		var fallback_enemy: Node2D = null
		var fallback_distance := INF
		var space_state = get_world_2d().direct_space_state

		if enemies.size() == 0:
			player_autoaim_previous_target = player_autoaim_target
			player_autoaim_target = null
			return
		
		# Check if previous target is still valid
		if player_autoaim_previous_target and not enemies.has(player_autoaim_previous_target):
			player_autoaim_previous_target = null
			player_autoaim_target = null
		
		for enemy in enemies:
			if enemy is CharacterBody2D:
				var dist = pos.distance_squared_to(enemy.global_position)
				# Store as fallback in case no enemies are visible
				if dist < fallback_distance:
					fallback_distance = dist
					fallback_enemy = enemy
				# Check line of sight
				var query = PhysicsRayQueryParameters2D.create(pos, enemy.global_position, 1)
				query.exclude = [enemy]
				var result = space_state.intersect_ray(query)
				# If no collision or collision is with the enemy, it's visible
				if result.is_empty() or result.collider == enemy:
					if dist < closest_distance:
						closest_distance = dist
						closest_enemy = enemy
		
		# Store previous target before updating current target
		player_autoaim_previous_target = player_autoaim_target
		
		# Handle target switching logic
		if closest_enemy:
			if player_autoaim_target and player_autoaim_target != closest_enemy:
				# Check if current target is still visible
				var current_query = PhysicsRayQueryParameters2D.create(pos, player_autoaim_target.global_position, 1)
				current_query.exclude = [player_autoaim_target]
				var current_result = space_state.intersect_ray(current_query)
				
				if current_result.is_empty() or current_result.collider == player_autoaim_target:
					# Current target still visible, check distance difference
					var current_distance = pos.distance_squared_to(player_autoaim_target.global_position)
					if closest_distance < current_distance - ENEMY_SWITCH_MINIMUM_DISTANCE * ENEMY_SWITCH_MINIMUM_DISTANCE:
						player_autoaim_target = closest_enemy
				else:
					# Current target not visible, switch to new target
					player_autoaim_target = closest_enemy
			else:
				player_autoaim_target = closest_enemy
		else:
			player_autoaim_target = fallback_enemy
		
