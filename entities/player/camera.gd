class_name PlayerCamera extends Camera2D

@export var shakeFade: float = 5.0
@export var enemy_lerp_speed: float = 3.0  # Speed of enemy position interpolation
@export var enemy_offset_factor = 0.1  # 3/10 of the distance

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
var max_dist_from_player: Vector2 = get_viewport_rect().size / 2
var current_enemy_offset := Vector2.ZERO

func _ready() -> void:
	Main.register_camera(self)

func apply_shake(strength: float = 5.0):
	shake_strength = strength

func _process(delta: float) -> void:
	var closest_enemy = Main.find_closest_enemy(self.global_position)
	
	var target_offset := Vector2.ZERO
	if closest_enemy:
		var to_enemy = closest_enemy.global_position - global_position
		target_offset = to_enemy * enemy_offset_factor
	
	current_enemy_offset = current_enemy_offset.lerp(target_offset, enemy_lerp_speed * delta)
	offset = current_enemy_offset
	
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		offset += randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
