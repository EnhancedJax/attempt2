class_name WeaponBase extends Node2D


signal signal_weapon_did_use(attack: AttackBase) # to be called by weapon implementation

@export var mag_size : int = -1

var firing_handler : FiringHandlerBase
var mag_count : int = mag_size

@onready var sprite2D : Sprite2D = $Sprite2D 
@onready var randomized_audio : AudioStreamPlayer2D = $RandomizedAudio
	
# /* ------------- Methods ------------ */

func update_sprite_flip(aim_pos: Vector2) -> void:
	scale.y = -abs(scale.y) if aim_pos.x < global_position.x else abs(scale.y)
	look_at(aim_pos)

# @ override
func handle_attack() -> void:
	print('shoot')

# @ override
func handle_out_of_ammo() -> void:
	print('out of ammo')

# @ override
func handle_reload() -> void:
	print('reload')
	mag_count = mag_size

# /* ------------ Interals ------------ */

func register_firing_handler(handler: FiringHandlerBase) -> void:
	firing_handler = handler
	print(firing_handler)

func handle_use(delta: float, auto_firing: bool) -> void:
	if firing_handler and firing_handler.is_to_attack(delta, auto_firing):
		if mag_count > 0 or mag_size == -1:
			handle_attack()
		else:
			handle_out_of_ammo()
			handle_reload()
