extends WeaponBase

var ATTACK = BulletType.new()

func _ready() -> void:
	mag_size = 6
	mag_count = mag_size
	Main.signal_player_equipped_weapon.connect(_on_weapon_equipped)
	bullet_spawner.signal_shot.connect(_on_shot)

func handle_attack() -> void:
	mag_count -= 1
	bullet_spawner.shoot()
	SoundManager.play_at_position_varied("shotgun", "shot", global_position, randf_range(0.8,1.2), 1)

func handle_reload() -> void:
	super.handle_reload()
	SoundManager.play("shotgun", "reload")
	$AnimatedSprite2D.play('reload')

func handle_finish_reload() -> void:
	mag_count = min(mag_size, mag_count + 1)
	can_reload = mag_size > mag_count
	signal_weapon_did_reload.emit()
	# if can_reload:
	# 	handle_reload()
	# else:
	SoundManager.play("shotgun", "cycle")
	$AnimatedSprite2D.play('idle')

func _on_weapon_equipped(node: Node2D):
	if self == node:
		$AnimatedSprite2D/AnimationPlayer.play("equip")
		SoundManager.play("shotgun", "cycle")

func _on_shot():
	$AnimatedSprite2D.play('idle')
	#$Sprite2D/AnimationPlayer.play("RESET")
	$AnimatedSprite2D.play('shot')
