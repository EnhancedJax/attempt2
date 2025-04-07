class_name HealthComponent extends Node

signal signal_health_deducted(health: int, MAX_HEALTH: int)
signal signal_health_healed(health: int, MAX_HEALTH: int)
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
	signal_health_deducted.emit(health, MAX_HEALTH)
	_check_dead()

func heal(amount: int):
	if is_dead:
		return
	health = min(health + amount, MAX_HEALTH)
	signal_health_healed.emit(health, MAX_HEALTH)
	_check_dead()

func _check_dead() -> void:
	if health <= 0:
		health = 0
		signal_health_depleted.emit()