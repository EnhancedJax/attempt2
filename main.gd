extends Node

var player : Player
var camera : PlayerCamera
var hud : HUD
var interaction_label : InteractionLabel

var interactions: Array[Interaction]
var is_paused: bool = false
const floor_item = preload("res://scenes/floor_item.tscn")
const weapons = [preload("res://weapons/protagonists/revolver/revolver.tscn"), preload("res://weapons/protagonists/m15/m_15.tscn"), preload("res://weapons/protagonists/shotgun/shotgun.tscn")]

func register_hud(h : HUD) -> void:
	hud = h
	update_health()

func register_player(p : Player) -> void:
	player = p

func register_camera(c : PlayerCamera) -> void:
	camera = c

func register_interaction_label(l : InteractionLabel) -> void:
	interaction_label = l

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		toggle_pause()
	if Input.is_action_just_pressed("interact"):
		if interactions.size() > 0:
			interactions[0].callable.call()
	if Input.is_action_just_pressed("dev"):
		var scene = floor_item.instantiate()
		scene.item = weapons[randi() % weapons.size()]
		scene.global_position = player.global_position 
		get_tree().current_scene.add_child(scene)

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

func update_health() -> void:
	if player:
		var health_component = player._health
		hud.update_health(health_component.health, health_component.MAX_HEALTH)

func register_interaction(i: Interaction):
	print('Interaction register', i)
	interactions.push_front(i)
	interaction_label.set_text(i.label)
	interaction_label.global_position = i.label_position
	interaction_label.visible = true

func reregister_interaction(i: Interaction):
	print('Interaction reregister', i)
	interaction_label.set_text(i.label)
	interaction_label.global_position = i.label_position
	interaction_label.visible = true

func deregister_interaction(i: Interaction):
	print('Interaction deregister', i)
	var index = 0
	for interaction in interactions:
		if interaction == i:
			break
		index += 1
	interactions.pop_at(index)
	if interactions.size() > 0:
		interaction_label.set_text(interactions[0].label)
		interaction_label.global_position = interactions[0].label_position
	else:
		interaction_label.visible = false
