extends RayCast2D

var BULLET : PackedScene
var ATTACK : BulletType

func shoot(towards: float) -> bool:
	var did_shoot = not is_colliding()
	if did_shoot and BULLET:
		var atk = ATTACK.duplicate()
		atk.towards_direction = towards
		# BULLET.SPEED = 500
		# BULLET.ATTACK = ATTACK
		var bullet = BULLET.instantiate()
		get_tree().root.add_child(bullet)

		bullet.global_position = global_position + target_position
		bullet.rotation = towards
	return did_shoot
