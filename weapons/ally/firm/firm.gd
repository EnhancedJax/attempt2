extends WeaponBase

@onready var reload_timer_2: Timer = $ReloadSound2Timer
@onready var reload_timer_3: Timer = $ReloadSound3Timer

func _ready() -> void:
	mag_size = 8
	mag_count = mag_size
	Main.signal_player_equipped_weapon.connect(_on_weapon_equipped)
	bullet_spawner.signal_shot.connect(_on_shot)
	reload_timer_2.timeout.connect(play_second_reload_sound)
	reload_timer_3.timeout.connect(play_third_reload_sound)

func handle_attack() -> void:
	bullet_spawner.shoot()
	mag_count -= 1
	SoundManager.play_at_position_varied("firm", "shot", global_position, randf_range(0.8,1.2), 1)	
	Main.camera.apply_shake(5)

func handle_reload() -> void:
	super.handle_reload()
	$AnimatedSprite2D.play('reload')
	SoundManager.play("firm", "reload_1")
	reload_timer_2.start()
	reload_timer_3.start()

func play_second_reload_sound() -> void:
	SoundManager.play("firm", "reload_2")

func play_third_reload_sound() -> void:
	SoundManager.play("firm", "rack")

func handle_finish_reload() -> void:
	super.handle_finish_reload()
	$AnimatedSprite2D.play('idle')

func _on_weapon_equipped(node: Node2D):
	if self == node:
		SoundManager.play("firm", "rack")
		$AnimatedSprite2D/AnimationPlayer.play("equip")

func _on_shot():
	$AnimatedSprite2D.play('idle')
	$AnimatedSprite2D.play('shot')
