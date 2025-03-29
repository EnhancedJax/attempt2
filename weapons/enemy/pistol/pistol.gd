
extends WeaponBase

@export var damage : int = 10
@export var knockback : float = 200.0
@export var recoil : float = 100.0
@export var spread : float = 5
const BULLET = preload("res://weapons/enemy/pistol/bullet.tscn")
var ATTACK = BulletType.new()

func _ready() -> void:
	ATTACK.damage = damage
	ATTACK.recoil = recoil
	ATTACK.knockback = knockback
	bullet_spawner.BULLET = BULLET
	bullet_spawner.ATTACK = ATTACK
	register_firing_handler($FullAutoComponent)

func handle_attack() -> void:
	pass
