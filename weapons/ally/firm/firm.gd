extends WeaponBase

@export var ATTACK : AttackBase
@export var spread : float = 10
@onready var bullet_spawner = $BulletSpawnerComponent
@onready var reload_timer_2: Timer = $ReloadSound2Timer
@onready var reload_timer_3: Timer = $ReloadSound3Timer
const BULLET = preload("res://weapons/ally/firm/firm_bullet.tscn")

func _ready() -> void:
	mag_size = 8
	mag_count = mag_size
	Main.signal_player_equipped_weapon.connect(rsignal_weapon_equipped)
	bullet_spawner.signal_shot.connect(rsignal_shot)
	bullet_spawner.register(ATTACK,BULLET)
	reload_timer_2.timeout.connect(play_second_reload_sound)
	reload_timer_3.timeout.connect(play_third_reload_sound)
	register_firing_handler($FullAutoComponent)

func handle_attack() -> void:
	mag_count -= 1
	var towards = rotation + deg_to_rad(randf_range(-spread, spread))
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = bullet_spawner.shoot(towards)
	if shot: 
		SoundManager.play_at_position_varied("firm", "shot", global_position, randf_range(0.8,1.2), 1)	
		Main.camera.apply_shake(5)
		emit_signal("signal_weapon_did_use", atk)

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

func rsignal_weapon_equipped(node: Node2D):
	if self == node:
		SoundManager.play("firm", "rack")
		$AnimatedSprite2D/AnimationPlayer.play("equip")

func rsignal_shot():
	$AnimatedSprite2D.play('idle')
	$AnimatedSprite2D.play('shot')
