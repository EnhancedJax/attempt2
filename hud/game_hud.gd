class_name HUD extends Control


@onready var minimap_generator = $Minimap/Clipper/MinimapGenerator
@onready var heart_container: HBoxContainer = $HeartConainer
@onready var heart : Control = $HeartConainer/Heart
@onready var weapon_texture: Sprite2D = $CanvasLayer/WeaponStaticSprite2D
@onready var coin_label: Label = $CoinLabel
@onready var shield_label: Label = $ShieldLabel
@onready var ammo_indicator = $AmmoIndicator
@onready var ammo_indicator_bar = $AmmoIndicator/ProgressBar
@onready var fps_label : Label = $FPSLabel
const heart_full_texture = preload('res://hud/heart_full_color.tres')
const heart_half_texture = preload('res://hud/heart_half_color.tres')
const title = preload("res://hud/title/title.tscn")

var current_max: int = 0  # store previous max health

func _ready() -> void:
	Main.register_hud(self)
	show_title('Test!')

func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func update_health(value: int = 1, max: int = 1):
	if value <= 1:
		$HealthWarn.visible = true
	else:
		$HealthWarn.visible = false
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

func update_coins(amount: int):
	coin_label.text = 'Coins: ' + str(amount)

func update_shield(is_active: bool):
	shield_label.text = 'Shield: ON' if is_active else 'Shield: OFF'

func update_ammo(count: int, max: int):
	ammo_indicator_bar.max_value = max
	ammo_indicator_bar.value = count
	ammo_indicator.text = "/".repeat(max)
	ammo_indicator_bar.size = ammo_indicator.get_minimum_size()
	ammo_indicator_bar.position.x = (ammo_indicator.size.x - ammo_indicator_bar.size.x) / 2

func draw_minimap(n):
	minimap_generator.draw_minimap(n)

func update_minimap(id):
	minimap_generator.update_minimap(id)


func _on_button_pressed() -> void:
	pass # Replace with function body.
