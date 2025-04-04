extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_player2: AnimationPlayer = $AnimationPlayer2
@export var sprite : Sprite2D
@export var crosshair_texture : CompressedTexture2D
@export var crosshair_texture2 : CompressedTexture2D
var self_aim_setting : ggsSetting = preload("res://game_settings/self_aim.tres")
var smoothing_speed = 15.0  # Adjust this value to control smoothing speed
var current_position = Vector2.ZERO
var player_is_dead : bool = false

func _ready() -> void:
	current_position = global_position
	Main.signal_player_landed_hit.connect(_on_player_landed_hit)
	Main.player.signal_player_death.connect(_on_player_death)
	GGS.setting_applied.connect(_on_setting_updated)
	_update_crosshair_mode(GGS.get_value_state(self_aim_setting))

func _on_setting_updated(setting: ggsSetting, value: Variant):
	if setting == self_aim_setting:
		_update_crosshair_mode(value)

func _update_crosshair_mode(is_self_aim: bool) -> void:
	if is_self_aim:
		self.visible = true
		animation_player.play("active")
		sprite.texture = crosshair_texture2
	else:
		self.visible = false
		sprite.texture = crosshair_texture

func _process(delta: float) -> void:
	if GGS.get_value_state(self_aim_setting):
		global_position = Main.player.get_aim_position()
	else:
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
		if player_is_dead:
			self.visible = false
			self.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			self.visible = false
			animation_player.play("RESET")
			animation_player2.play("RESET")

func _on_player_landed_hit():
	animation_player2.play("RESET")
	animation_player2.play("hit")

func _on_player_death():
	player_is_dead = true
	animation_player2.play("exit")
