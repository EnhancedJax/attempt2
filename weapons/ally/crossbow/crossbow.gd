extends WeaponBase

func _ready() -> void:
	mag_size = 1
	mag_count = mag_size
	Main.signal_player_equipped_weapon.connect(rsignal_weapon_equipped)
	bullet_spawner.signal_shot.connect(rsignal_shot)

func handle_attack() -> void:
	mag_count -= 1
	bullet_spawner.shoot()
	#SoundManager.play_at_position_varied("firm", "shot", global_position, randf_range(0.8,1.2), 1)	

func handle_reload() -> void:
	super.handle_reload()
	$AnimatedSprite2D.play('reload')
	#SoundManager.play("firm", "reload_1")

func handle_finish_reload() -> void:
	super.handle_finish_reload()
	$AnimatedSprite2D.play('idle')

func rsignal_weapon_equipped(node: Node2D):
	if self == node:
		SoundManager.play("firm", "rack")
		$AnimatedSprite2D/AnimationPlayer.play("equip")

func rsignal_shot():
	$AnimatedSprite2D.play('idle')
	$AnimatedSprite2D.play('shot')
