class_name WeaponBase extends Node2D


signal signal_weapon_did_use(attack: AttackBase) # to be called by weapon implementation

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

func handle_use(delta: float, auto_firing: bool) -> void:
	if firing_handler and firing_handler.is_to_attack(delta, auto_firing):
		attack()
