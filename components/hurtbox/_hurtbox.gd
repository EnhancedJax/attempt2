class_name HurtboxComponent extends Area2D

signal signal_hit(attack: AttackBase)

func _on_body_entered(body: Node2D) -> void:
	print('[HURTBOX] Body entered: ', body, ' has attack: ', 'ATTACK' in body, ' (Parent: ', self.get_parent(), ' )')
	if "ATTACK" in body:
		handle_hit(body)
	
func handle_hit(body: Node2D) -> void:
	signal_hit.emit(body.ATTACK)
	if body.has_method("handle_hit"):
		body.handle_hit()
