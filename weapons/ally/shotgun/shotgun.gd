extends WeaponBase

@export var damage : int = 10
@export var knockback : float = 200.0
@export var recoil : float = 100.0
@onready var bullet_spawner = $BasicShotgun
@onready var audio_bus_1 = $AudioBus1
@onready var audio_bus_2 = $AudioBus2
const BULLET = preload("res://weapons/ally/shotgun/shotgun_bullet.tscn")
var ATTACK = BulletType.new()

func _ready() -> void:
	mag_size = 6
	mag_count = mag_size
	Main.signal_player_equipped_weapon.connect(rsignal_weapon_equipped)
	bullet_spawner.signal_shot.connect(rsignal_shot)
	ATTACK.damage = damage
	ATTACK.recoil = recoil
	ATTACK.knockback = knockback
	bullet_spawner.BULLET = BULLET
	bullet_spawner.ATTACK = ATTACK
	register_firing_handler($SemiAutoComponent)

func handle_attack() -> void:
	mag_count -= 1
	var towards = rotation
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = bullet_spawner.shoot(towards)
	if shot: 
		SoundManager.play_at_position_varied("shotgun", "shot", global_position, randf_range(0.8,1.2), 1)
		emit_signal("signal_weapon_did_use", atk)

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

func rsignal_weapon_equipped(node: Node2D):
	if self == node:
		$AnimatedSprite2D/AnimationPlayer.play("equip")
		SoundManager.play("shotgun", "cycle")

func rsignal_shot():
	$AnimatedSprite2D.play('idle')
	#$Sprite2D/AnimationPlayer.play("RESET")
	$AnimatedSprite2D.play('shot')
