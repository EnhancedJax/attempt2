class_name PlayerCamera extends Camera2D

@export var shakeFade: float = 5.0
@export var enemy_lerp_speed: float = 3.0  # Speed of enemy position interpolation
@export var enemy_offset_factor = 0.1  # 3/10 of the distance
@export var boss_focus_move_duration = 1.0  # Duration of moving the camera to the boss (back and forth)
@export var boss_focus_duration = 1.5  # Duration of boss focus

var focusing_boss : BossBase = null
var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
var max_dist_from_player: Vector2 = get_viewport_rect().size / 2
var current_enemy_offset := Vector2.ZERO
var focus_timer: float = 0.0

func _ready() -> void:
	Main.register_camera(self)

func apply_shake(strength: float = 5.0):
	shake_strength = strength / 4

func focus_boss(b: BossBase) -> void:
	focusing_boss = b
	focus_timer = 0.0

func _process(delta: float) -> void:
	if focusing_boss:
		_process_focus_boss(delta)
	else:
		_process_shift_enemy(delta)
	
	_process_shake(delta)

func _process_shake(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		offset += randomOffset()
	
func _process_focus_boss(delta: float) -> void:
	focus_timer += delta
	var total_duration = boss_focus_move_duration * 2 + boss_focus_duration
	
	if focus_timer >= total_duration:
		offset = current_enemy_offset
		focusing_boss = null
		return
	
	var target_pos = focusing_boss.global_position - Main.player.global_position
	
	if focus_timer < boss_focus_move_duration:
		# Moving to boss
		var t = focus_timer / boss_focus_move_duration
		offset = current_enemy_offset.lerp(target_pos, t)
	elif focus_timer < boss_focus_move_duration + boss_focus_duration:
		# Holding on boss
		offset = target_pos
	else:
		# Moving back to player
		var t = (focus_timer - boss_focus_move_duration - boss_focus_duration) / boss_focus_move_duration
		offset = target_pos.lerp(current_enemy_offset, t)

func _process_shift_enemy(delta: float) -> void:
	var target_offset := Vector2.ZERO
	if Main.player_autoaim_target:
		var to_enemy = Main.player_autoaim_target.global_position - global_position
		target_offset = to_enemy * enemy_offset_factor
	
	current_enemy_offset = current_enemy_offset.lerp(target_offset, enemy_lerp_speed * delta)
	offset = current_enemy_offset

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
