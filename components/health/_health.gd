class_name HealthComponent extends Node

signal signal_health_deducted(health: int, MAX_HEALTH: int)
signal signal_health_depleted()

@export var MAX_HEALTH: int = 5
@export var INITIAL_HEALTH: int = 5
var health: int
var is_dead : bool = false

func _ready() -> void:
	health = INITIAL_HEALTH

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	emit_signal("signal_health_deducted", health, MAX_HEALTH)
	if health <= 0:
		health = 0
		is_dead = true
		emit_signal("signal_health_depleted")
