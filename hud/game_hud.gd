class_name HUD extends Control


@onready var heart_container: HBoxContainer = $HeartConainer
@onready var heart : Control = $HeartConainer/Heart
@onready var weapon_texture: TextureRect = $WeaponContainer/MarginContainer/AspectRatioContainer/TextureRect
const heart_full_texture = preload('res://hud/heart_full_color.tres')
const heart_half_texture = preload('res://hud/heart_half_color.tres')
const title = preload("res://hud/title/title.tscn")

var current_max: int = 0  # store previous max health

func _ready() -> void:
	Main.register_hud(self)
	show_title('Test!')

func update_health(value: int = 1, max: int = 1):
	# Update hearts if max changed
	if max != current_max:
		var hearts_needed = int(ceil(max / 2.0))
		var current_hearts = heart_container.get_child_count()
		# Add new hearts if fewer than needed
		while current_hearts < hearts_needed:
			var new_heart = heart.duplicate()
			heart_container.add_child(new_heart)
			current_hearts += 1
		# Remove hearts if more than needed
		while current_hearts > hearts_needed:
			heart_container.get_child(current_hearts - 1).queue_free()
			current_hearts -= 1
		current_max = max
	
	# Update each heart's appearance based on current value
	for i in range(heart_container.get_child_count()):
		var hp_in_heart = clamp(value - (i * 2), 0, 2)
		var heart_node = heart_container.get_child(i)
		var icon = heart_node.get_child(1)
		if hp_in_heart == 2:
			icon.texture = heart_full_texture
			icon.visible = true
		elif hp_in_heart == 1:
			icon.texture = heart_half_texture
			icon.visible = true
		else:
			icon.visible = false

func update_equipped_weapon(weapon: Lookup.WeaponType):
	weapon_texture.texture = Lookup.get_weapon_texture(-1, weapon)

func show_title(str: String):
	var scene = title.instantiate()
	scene.set_text(str)
	add_child(scene)


func load_minimap(room_nodes: Array):
	pass
