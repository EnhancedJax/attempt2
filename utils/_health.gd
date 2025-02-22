extends Node
class_name _Health

signal signal_damage(health, MAX_HEALTH, damage)
signal signal_health_depleted(health, MAX_HEALTH, damage)

@export var MAX_HEALTH := 10
var health : int

func _ready():
	health = MAX_HEALTH

func do_damage(damage : int):
	health -= damage

	if health <= 0:
		signal_health_depleted.emit(health, MAX_HEALTH, damage)
	else:
		signal_damage.emit(health, MAX_HEALTH, damage)
