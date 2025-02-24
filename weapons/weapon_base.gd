class_name WeaponBase extends Node2D

enum FiringMode {
	AUTO = 0,
	SEMI_AUTO = 1,
	SINGLE_ROUND = 2
}

signal signal_weapon_did_use(attack: AttackBase)

@export var weapon_name : StringName
@export_category("Weapon orientation")
@export var sprite_position : Vector2 = Vector2(0, 0)
@export var sprite_rotation : float = 0
@export var sprite_scale : Vector2 = Vector2(1, 1)
@export_category("Weapon assets")
@export var texture : CompressedTexture2D
@export_category("Weapon firing")
@export var firing_mode : FiringMode = FiringMode.AUTO
@export var fire_rate : int = 5
@export_category("Weapon audio")
@export var fire_sound : AudioStream

@onready var sprite2D : Sprite2D = $Sprite2D
@onready var randomized_audio : AudioStreamPlayer2D = $RandomizedAudio
var fire_timer: float = 1.0 / fire_rate
	
# /* ------------- Methods ------------ */

func update_sprite_flip(aim_pos: Vector2) -> void:
	scale.y = -abs(scale.y) if aim_pos.x < global_position.x else abs(scale.y)
	look_at(aim_pos)

func attack() -> void:
	print('attack')

# /* ------------ Internals ----------- */

func handle_use(delta: float) -> void:
	fire_timer += delta
	
	match firing_mode:
		WeaponResource.FiringMode.AUTO:
			handle_auto_fire()
		WeaponResource.FiringMode.SEMI_AUTO:
			handle_semi_auto_fire()

func handle_auto_fire() -> void:
	if Input.is_action_pressed("fire") and fire_timer >= (1.0 / fire_rate):
		attack()
		fire_timer = 0

func handle_semi_auto_fire() -> void:
	if Input.is_action_just_pressed("fire") and fire_timer >= (1.0 / fire_rate):
		attack()
		fire_timer = 0