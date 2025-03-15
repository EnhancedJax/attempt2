class_name WeaponBase extends Node2D


signal signal_weapon_did_use(attack: AttackBase) # to be called by weapon implementation
signal signal_weapon_reloading(duration: float) # to be called by weapon implementation

@export var mag_size : int = -1
@export var reload_time : float = 0.5
@export var audio_streams : Array[AudioStream]

var firing_handler : FiringHandlerBase
var mag_count : int = mag_size
var can_reload : bool = false
var is_reloading : bool = false

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
	can_reload = false
	is_reloading = true
	signal_weapon_reloading.emit(reload_time)

# @ override
func handle_finish_reload() -> void:
	mag_count = mag_size

func call_reload() -> void:
	handle_reload()

func call_stop_reload() -> void:
	is_reloading = false
	can_reload = true

func call_finish_reload() -> void:
	is_reloading = false
	can_reload = false
	handle_finish_reload()

# /* ------------ Interals ------------ */

func register_firing_handler(handler: FiringHandlerBase) -> void:
	firing_handler = handler
	print(firing_handler)

func handle_use(delta: float, auto_firing: bool) -> void:
	if firing_handler and firing_handler.is_to_attack(delta, auto_firing):
		if (mag_count > 0 or mag_size == -1) and not is_reloading:
			handle_attack()
			can_reload = mag_size != -1 and mag_count < mag_size
			if mag_count > 0:
				return
		handle_out_of_ammo()
		if can_reload:
			handle_reload()
