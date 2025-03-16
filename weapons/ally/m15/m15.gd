extends WeaponBase

@export var damage : int = 10
@export var knockback : float = 200.0
@export var recoil : float = 100.0
@export var spread : float = 5
@onready var bullet_spawner = $BulletSpawnerComponent
@onready var reload_timer: Timer = $ReloadSound2Timer
const BULLET = preload("res://weapons/ally/m15/m15_bullet.tscn")
var ATTACK = BulletType.new()

func _ready() -> void:
	mag_size = 30
	mag_count = mag_size
	Main.signal_player_equipped_weapon.connect(rsignal_weapon_equipped)
	bullet_spawner.signal_shot.connect(rsignal_shot)
	ATTACK.damage = damage
	ATTACK.recoil = recoil
	ATTACK.knockback = knockback
	bullet_spawner.BULLET = BULLET
	bullet_spawner.ATTACK = ATTACK
	reload_timer.timeout.connect(play_halfway_reload_sound)
	register_firing_handler($FullAutoComponent)

func handle_attack() -> void:
	mag_count -= 1
	var towards = rotation + deg_to_rad(randf_range(-spread, spread))
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = bullet_spawner.shoot(towards)
	if shot: 
		$AudioBus1.play()
		emit_signal("signal_weapon_did_use", atk)

func handle_reload() -> void:
	super.handle_reload()
	$AnimatedSprite2D.play('reload')
	$AudioBus2.stream = audio_streams[0]
	$AudioBus2.play()
	reload_timer.start(reload_time / 2)

func play_halfway_reload_sound() -> void:
	$AudioBus2.stream = audio_streams[1]
	$AudioBus2.play()

func handle_finish_reload() -> void:
	super.handle_finish_reload()
	$AnimatedSprite2D.play('idle')

func rsignal_weapon_equipped(node: Node2D):
	if self == node:
		$AnimatedSprite2D/AnimationPlayer.play("equip")

func rsignal_shot():
	$AnimatedSprite2D.play('idle')
	$AnimatedSprite2D.play('shot')
	#$AnimatedSprite2D/AnimationPlayer.play("RESET")
	#$AnimatedSprite2D/AnimationPlayer.play("shot")
