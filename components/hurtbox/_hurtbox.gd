class_name HurtboxComponent extends Area2D

signal signal_hit(attack: AttackBase)

func _on_body_entered(body: Node2D) -> void:
	if body is BulletBase:
		emit_signal("signal_hit", body.ATTACK)
		body.handle_hit()
