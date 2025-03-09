class_name PlayerCamera extends Camera2D

@export var shakeFade: float = 5.0
const ENEMY_OFFSET_FACTOR = 0.1  # 3/10 of the distance

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
var max_dist_from_player: Vector2 = get_viewport_rect().size / 2

func _ready() -> void:
	Main.register_camera(self)

func apply_shake(strength: float = 5.0):
	shake_strength = strength

func _process(delta: float) -> void:
	if Main.player:
		var base_pos = Main.player.global_position
		var closest_enemy = Main.find_closest_enemy(self.global_position)
		
		if closest_enemy:
			var to_enemy = closest_enemy.global_position - base_pos
			base_pos += to_enemy * ENEMY_OFFSET_FACTOR
		
		self.global_position = base_pos
		
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		offset = randomOffset()

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
