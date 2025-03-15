extends RayCast2D

@export var PELLET_COUNT = 5
@export var SPREAD_ANGLE = 30.0  # Total spread angle in degrees

var BULLET : PackedScene
var ATTACK : BulletType

signal signal_shot()

func shoot(towards: float) -> bool:
	var is_colliding = self.is_colliding()
	if is_colliding:
		var collider = self.get_collider()
		if collider is TileMapLayer:
			return false
	if BULLET:
		for i in range(PELLET_COUNT):
			var spread = deg_to_rad(SPREAD_ANGLE) * (float(i) / (PELLET_COUNT - 1) - 0.5)
			var final_angle = towards + spread
			
			var atk = ATTACK.duplicate()
			atk.towards_vector = Vector2(cos(final_angle), sin(final_angle))
			var bullet = BULLET.instantiate()
			bullet.register_attack(atk)
			get_tree().root.add_child(bullet)
				
			var global_target_offset : Vector2
			if not is_colliding:
				global_target_offset = target_position.rotated(final_angle) * abs(global_scale)
			bullet.global_position = global_position + global_target_offset
			bullet.rotation = final_angle
		signal_shot.emit()
	return true
