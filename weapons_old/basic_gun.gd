class_name BasicGun extends Weapon

const BULLET = preload('res://weapons/bullet.tscn')
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var raycast: RayCast2D = $RayCast2D

func shoot() -> bool:
	var did_shoot = not raycast.is_colliding()
	if did_shoot:
		super.shoot()
		randomized_audio.play()
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		configure_bullet(bullet_instance)
		randomized_audio.play()
	return did_shoot

func build_tree() -> void:
	super.build_tree()
	bullet_spawn = Marker2D.new()
	add_child(bullet_spawn)
	bullet_spawn.position = WEAPON.bullet_spawn
	raycast = RayCast2D.new()
	add_child(raycast)
	raycast.enabled = true
	raycast.position = Vector2(0,0)
	raycast.target_position = WEAPON.bullet_spawn

func configure_bullet(bullet: Node2D) -> void:
	bullet.global_position = get_bullet_spawn_position()
	bullet.owner_node = parent
	var random_spread = randf_range(-WEAPON.spread, WEAPON.spread)
	bullet.rotation = rotation + deg_to_rad(random_spread)
	var atk = Attack.new()
	atk.damage = WEAPON.damage
	atk.recoil = WEAPON.recoil
	atk.knockback = WEAPON.knockback
	atk.direction = Vector2.RIGHT.rotated(bullet.rotation)
	atk.source = parent
	bullet.attack = atk
	
	# Apply recoil to shooter
	if atk.source is EntityBase:
		atk.source.apply_force(-atk.direction * atk.recoil)

func get_bullet_spawn_position() -> Vector2:
	return bullet_spawn.global_position
