
extends WeaponBase

func _ready() -> void:
	pass

func handle_attack() -> void:
	bullet_spawner.shoot()
