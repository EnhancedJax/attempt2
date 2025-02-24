extends WeaponBase

@export var damage : int = 10
@export var knockback : float = 200.0
@export var recoil : float = 100.0
@export var spread : float = 5
@onready var bullet_spawner = $BulletSpawnerComponent
const BULLET = preload("res://weapons/m15/m_15_bullet.tscn")
var ATTACK = BulletType.new()

func _ready() -> void:
	ATTACK.damage = damage
	ATTACK.recoil = recoil
	ATTACK.knockback = knockback
	bullet_spawner.BULLET = BULLET
	bullet_spawner.ATTACK = ATTACK

func attack() -> void:
	var towards = rotation + deg_to_rad(randf_range(-spread, spread))
	var shot = bullet_spawner.shoot(towards)
	if shot: 
		randomized_audio.play()
		emit_signal("signal_weapon_did_use")
