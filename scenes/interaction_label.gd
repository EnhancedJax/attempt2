class_name InteractionLabel extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Main.register_interaction_label(self)

func set_text(text: String):
	$Label.text = text
