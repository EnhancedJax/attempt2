extends FiringHandlerBase

@export var fire_rate : int
var fire_timer: float = 0
var fire_rate_time : float

func _ready() -> void:
	fire_rate_time = 1.0 / fire_rate
	fire_timer = fire_rate_time

func _process(delta: float) -> void:
	# Update the fire timer without calling is_to_attack, so when not checking for fire, the timer still updates
	fire_timer = min(fire_timer + delta, fire_rate_time)

func is_to_attack(delta: float, auto_firing: bool) -> bool:
	if Input.is_action_just_pressed("fire") and fire_timer >= fire_rate_time:
		fire_timer = 0
		return true
	return false
