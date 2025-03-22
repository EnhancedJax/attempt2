extends WeaponBase

@export var ATTACK : AttackBase
@export var spread : float = 5
@onready var bullet_spawner = $BulletSpawnerComponent
@onready var reload_timer: Timer = $ReloadSound2Timer
const BULLET = preload("res://weapons/ally/sniper/sniper_bullet.tscn")

func _ready() -> void:
	Main.signal_player_equipped_weapon.connect(rsignal_weapon_equipped)
	bullet_spawner.signal_shot.connect(rsignal_shot)
	bullet_spawner.register(ATTACK, BULLET)
	reload_timer.timeout.connect(play_halfway_reload_sound)
	register_firing_handler($SemiAutoComponent)

func handle_attack() -> void:
	mag_count -= 1
	var towards = rotation + deg_to_rad(randf_range(-spread, spread))
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = bullet_spawner.shoot(towards)
	if shot: 
		SoundManager.play_at_position_varied("sniper", "shot", global_position, randf_range(0.8,1.2), 1)
		Main.camera.apply_shake(25)
		emit_signal("signal_weapon_did_use", atk)

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

func rsignal_weapon_equipped(node: Node2D):
	if self == node:
		SoundManager.play("sniper", "cycle")
		$AnimatedSprite2D/AnimationPlayer.play("equip")

func rsignal_shot():
	$AnimatedSprite2D.play('idle')
	$AnimatedSprite2D.play('shot')
	$AnimatedSprite2D/AnimationPlayer.play('shot')
