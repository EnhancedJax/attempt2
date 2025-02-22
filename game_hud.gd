extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func update_health(value: int = 1, max: int = 1):
	$HealthBar.update(value, max)

var is_paused: bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
