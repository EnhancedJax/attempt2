class_name WeaponBase extends Node2D

signal signal_weapon_did_use(attack: AttackBase) # to be called by weapon implementation

@export var weapon_name : StringName
@export_category("Weapon orientation")
@export var sprite_position : Vector2 = Vector2(0, 0)
@export var sprite_rotation : float = 0
@export var sprite_scale : Vector2 = Vector2(1, 1)
@export_category("Weapon assets")
@export var texture : CompressedTexture2D
@export_category("Weapon audio")
@export var fire_sound : AudioStream
var firing_handler : FiringHandlerBase

@onready var sprite2D : Sprite2D = $Sprite2D
@onready var randomized_audio : AudioStreamPlayer2D = $RandomizedAudio
	
# /* ------------- Methods ------------ */

func update_sprite_flip(aim_pos: Vector2) -> void:
	scale.y = -abs(scale.y) if aim_pos.x < global_position.x else abs(scale.y)
	look_at(aim_pos)

# @ override
func attack() -> void:
	print('shoot')

# /* ------------ Interals ------------ */

func register_firing_handler(handler: FiringHandlerBase) -> void:
	firing_handler = handler
	print(firing_handler)

func handle_use(delta: float) -> void:
	if firing_handler and firing_handler.is_to_attack(delta):
		attack()
