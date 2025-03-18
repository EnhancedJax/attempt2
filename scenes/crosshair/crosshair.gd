extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_player2: AnimationPlayer = $AnimationPlayer2
var smoothing_speed = 15.0  # Adjust this value to control smoothing speed
var current_position = Vector2.ZERO

func _ready() -> void:
	current_position = global_position
	Main.signal_player_landed_hit.connect(rsignal_player_landed_hit)

func _process(delta: float) -> void:
	var target = Main.player_autoaim_target
	var previous_target = Main.player_autoaim_previous_target

	if target != null and previous_target != target:
		animation_player.play("active")

	if target:
		self.visible = true
		current_position = current_position.lerp(target.global_position, smoothing_speed * delta)
		self.global_position = current_position
	else:
		animation_player2.play("exit")
		current_position = Main.player.global_position
		


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "exit":
		self.visible = false
		animation_player.play("RESET")
		animation_player2.play("RESET")

func rsignal_player_landed_hit():
	animation_player2.play("RESET")
	animation_player2.play("hit")
