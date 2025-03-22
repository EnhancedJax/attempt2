extends FiringHandlerBase

@export var fire_rate : int
var fire_timer: float = 0
var fire_rate_time : float

func _ready() -> void:
	fire_rate_time = 1.0 / fire_rate
	fire_timer = fire_rate_time

func is_to_attack(delta: float, is_just_pressed_fire: bool, is_pressed_fire: bool, auto_firing: bool) -> bool:
	fire_timer = min(fire_timer + delta, fire_rate_time)
	if (auto_firing or is_pressed_fire) and fire_timer >= fire_rate_time:
		fire_timer = 0
		return true
	return false
