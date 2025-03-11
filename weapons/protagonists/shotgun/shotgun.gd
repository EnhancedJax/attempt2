extends WeaponBase

@export var damage : int = 10
@export var knockback : float = 200.0
@export var recoil : float = 100.0
@export var spread : float = 5
@onready var bullet_spawner = $BasicShotgun
const BULLET = preload("res://weapons/protagonists/shotgun/shotgun_bullet.tscn")
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
	var towards = rotation + deg_to_rad(randf_range(-spread, spread))
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = bullet_spawner.shoot(towards)
	if shot: 
		randomized_audio.play()
		emit_signal("signal_weapon_did_use", atk)

func handle_finish_reload() -> void:
	mag_count = min(mag_size, mag_count + 1)
	can_reload = mag_size > mag_count

func rsignal_weapon_equipped(node: Node2D):
	if self == node:
		$Sprite2D/AnimationPlayer.play("equip")

func rsignal_shot():
	$Sprite2D/AnimationPlayer.play("RESET")
	$Sprite2D/AnimationPlayer.play("shot")
