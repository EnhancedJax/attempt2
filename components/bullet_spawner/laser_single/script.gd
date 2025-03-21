extends Node2D

@export var BULLET : PackedScene
var ATTACK : AttackBase

signal signal_shot()

func register_attack(atk: AttackBase):
	self.ATTACK = atk

func shoot(towards: float) -> bool:
	if BULLET:
		var atk = ATTACK.duplicate()
		atk.towards_vector = Vector2(cos(towards), sin(towards))
		var bullet = BULLET.instantiate()
		bullet.register_attack(atk)
		Main.control.get_child(0).add_child(bullet)
			
		bullet.global_position = global_position
		signal_shot.emit()
	return true
