extends Node

var player : Player
var camera : PlayerCamera
var hud : HUD

func register_hud(h : HUD) -> void:
	hud = h
	update_health()

func register_player(p : Player) -> void:
	player = p

func register_camera(c : PlayerCamera) -> void:
	camera = c

var is_paused: bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

func update_health() -> void:
	if player:
		var health_component = player._health
		hud.update_health(health_component.health, health_component.MAX_HEALTH)
