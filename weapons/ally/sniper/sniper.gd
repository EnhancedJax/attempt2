extends WeaponBase

@onready var reload_timer: Timer = $ReloadSound2Timer

func _ready() -> void:
	Main.signal_player_equipped_weapon.connect(_on_weapon_equipped)
	bullet_spawner.signal_shot.connect(_on_shot)
	reload_timer.timeout.connect(play_halfway_reload_sound)

func handle_attack() -> void:
	mag_count -= 1
	bullet_spawner.shoot()
	SoundManager.play_at_position_varied("sniper", "shot", global_position, randf_range(0.8,1.2), 1)

func handle_reload() -> void:
	super.handle_reload()
	$AnimatedSprite2D/AnimationPlayer.play('reload')
	SoundManager.play("sniper", "reload_1")
	reload_timer.start(reload_time / 2)
#
func play_halfway_reload_sound() -> void:
	SoundManager.play("sniper", "reload_2")

func handle_finish_reload() -> void:
	super.handle_finish_reload()
	$AnimatedSprite2D.play('idle')
	SoundManager.play("sniper", "cycle")

func _on_weapon_equipped(node: Node2D):
	if self == node:
		SoundManager.play("sniper", "cycle")
		$AnimatedSprite2D/AnimationPlayer.play("equip")

func _on_shot():
	$AnimatedSprite2D.play('idle')
	$AnimatedSprite2D.play('shot')
	$AnimatedSprite2D/AnimationPlayer.play('shot')
