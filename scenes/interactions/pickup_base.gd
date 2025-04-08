extends InteractionSource

@export var label_position : Marker2D
@export var item_sprite : Sprite2D
@export var shine_material : ShaderMaterial
@export var selected_material : ShaderMaterial

func _ready() -> void:
	Main.signal_interaction_changed.connect(handle_interaction_changed)

func register(callable: Callable, params : Array[int], price: int) -> void:
	i = Interaction.new()
	i.callable = callable
	i.source = self
	i.price = price
	i.label_position = label_position.global_position
	i_params = params

func update_item_meta(label: String, texture: Texture2D) -> void:
	i.label = label
	item_sprite.texture = texture
	
func handle_interaction_changed(_i: Interaction) -> void:
	if _i != i:
		item_sprite.material = shine_material

func _on_player_entered() -> void:
	Main.register_interaction(i)
	item_sprite.material = selected_material

func _on_player_exited() -> void:
	Main.deregister_interaction(i)
	item_sprite.material = shine_material
