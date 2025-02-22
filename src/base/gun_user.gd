class_name GunUser extends EntityBase


# Must be implemented by children
func get_aim_position() -> Vector2:
	return Vector2.ZERO

# Optional to implement
func on_weapon_fired():
	pass
