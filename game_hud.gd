class_name HUD extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Main.register_hud(self)

func update_health(value: int = 1, max: int = 1):
	$HealthBar.update(value, max)
