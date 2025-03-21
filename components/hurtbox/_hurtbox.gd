class_name HurtboxComponent extends Area2D

signal signal_hit(attack: AttackBase)

func _on_body_entered(body: Node2D) -> void:
	print('body', body)
	if body is BulletBase:
		handle_hit(body)
	
func handle_hit(body: Node2D) -> void:
	emit_signal("signal_hit", body.ATTACK)
	body.handle_hit()
