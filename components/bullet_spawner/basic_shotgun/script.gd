extends RayCast2D

@export var PELLET_COUNT = 5
@export var SPREAD_ANGLE = 30.0  # Total spread angle in degrees

var BULLET : PackedScene
var ATTACK : BulletType

func shoot(towards: float) -> bool:
	var did_shoot = not is_colliding()
	if did_shoot and BULLET:
		for i in range(PELLET_COUNT):
			var spread = deg_to_rad(SPREAD_ANGLE) * (float(i) / (PELLET_COUNT - 1) - 0.5)
			var final_angle = towards + spread
			
			var atk = ATTACK.duplicate()
			atk.towards_vector = Vector2(cos(final_angle), sin(final_angle))
			var bullet = BULLET.instantiate()
			bullet.register_attack(atk)
			get_tree().root.add_child(bullet)

			var global_target_offset = target_position.rotated(final_angle) * abs(global_scale)
			bullet.global_position = global_position + global_target_offset
			bullet.rotation = final_angle
	return did_shoot
