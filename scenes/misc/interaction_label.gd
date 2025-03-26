class_name InteractionLabel extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Main.register_interaction_label(self)

func display(text: String, gp: Vector2):
	$Label.text = text
	global_position = gp
	visible = true
	$AnimationPlayer.play("enter")

func remove():
	visible = false
	$Label.text = ""
