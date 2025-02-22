extends Area2D

@export var _health : _Health

func do_hit(damage : int):
	_health.do_damage(damage)
