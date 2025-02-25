class_name HitboxComponent extends Area2D

signal signal_hit(attack: AttackBase)

func hit(attack: AttackBase) -> void:
	print(self, 'Hit!')
	emit_signal("signal_hit", attack)
