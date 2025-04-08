class_name InteractionLabel extends Control

@export var animation_player : AnimationPlayer
#@export var shake_animation_player : AnimationPlayer
@export var label : Label
@export var price_group: Container
@export var price_label : Label

func _ready() -> void:
	Main.register_interaction_label(self)

func display(text: String, gp: Vector2, price: int = -1) -> void:
	label.text = text
	global_position = gp
	visible = true
	if price == -1:
		price_group.visible = false
	else:
		price_group.visible = true
		price_label.text = str(price)
	animation_player.play("enter")

func shake() -> void:
	pass
	#shake_animation_player.play("shake")

func remove():
	visible = false
	label.text = ""
