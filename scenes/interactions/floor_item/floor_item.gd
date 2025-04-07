class_name FloorItem
extends InteractionSource

@export var animation_player : AnimationPlayer
@export var label_position : Marker2D
@export var item_sprite : Sprite2D

func _ready() -> void:
	Main.signal_interaction_changed.connect(handle_interaction_changed)
	# _update_item_metadata()

func register(callable: Callable, params : Array[int]) -> void:
	i = Interaction.new()
	i.callable = callable
	i.source = self
	i.label_position = label_position.global_position
	i_params = params

func update_item_meta(label: String, texture: Texture2D) -> void:
	i.label = label
	item_sprite.texture = texture
	
func handle_interaction_changed(_i: Interaction) -> void:
	if _i != i:
		item_sprite.material.set_shader_parameter("width", 0)

func _on_player_entered() -> void:
	Main.register_interaction(i)
	item_sprite.material.set_shader_parameter("width", 1)

func _on_player_exited() -> void:
	Main.deregister_interaction(i)
	item_sprite.material.set_shader_parameter("width", 0)
