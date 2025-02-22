extends GenericGun

@onready var bullet_spawn: Marker2D = $BulletSpawn

func _ready() -> void:
	damage = 1  # Configure default damage

func _process(delta: float) -> void:
	super._process(delta)
	update_sprite_flip()

func update_sprite_flip() -> void:
	var gun_user = get_parent()
	if gun_user.has_method("get_aim_position"):
		var aim_pos = gun_user.get_aim_position()
		$SpriteWrapper/GunSprite.scale.y = -1 if aim_pos.x < global_position.x else 1

func get_bullet_spawn_position() -> Vector2:
	return bullet_spawn.global_position

func shoot() -> void:
	if not $RayCast2D.is_colliding():
		super.shoot()
		var gun_user = get_parent()
		if gun_user.has_method("on_weapon_fired"):
			gun_user.on_weapon_fired()
