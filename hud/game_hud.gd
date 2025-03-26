class_name HUD extends Control


@export var minimap_generator : Control
@export var heart_container: HBoxContainer
@export var heart : Control
@export var weapon_texture: TextureRect
@export var coin_label: Label
@export var ammo_indicator : Label 
@export var ammo_indicator_bar : ProgressBar
@export var fps_label : Label
@export var action_texture : TextureRect
@export var boss_bar : Control
@export var boss_bar_progress : ProgressBar
const heart_full_texture = preload('res://hud/heart_full_color.tres')
const heart_half_texture = preload('res://hud/heart_half_color.tres')
const heart_empty_texture = preload('res://hud/heart_empty_color.tres')
const heart_full_shield_texture = preload('res://hud/heart_full_shield.tres')
const heart_half_shield_texture = preload('res://hud/heart_half_shield.tres')
const heart_empty_shield_texture = preload('res://hud/heart_empty_shield.tres')
var action_shoot_texture = preload("res://hud/shoot.png")
var action_interact_texture = preload("res://hud/interact.png")
const title = preload("res://hud/title/title.tscn")

var current_max: int = 0  # store previous max health
var shield_active: bool = true  # track shield state

var _cache_player_max_health: int = 0
var _cache_player_health: int = 0

func _ready() -> void:
	Main.register_hud(self)
	show_title('Test!')
	Main.signal_interaction_changed.connect(rsignal_interaction_changed)
	Main.signal_player_room_cleared.connect(rsignal_player_room_cleared)
	Main.signal_player_room_changed.connect(rsignal_player_room_changed)

func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func rsignal_interaction_changed(i: Interaction):
	if i == null:
		action_texture.texture = action_shoot_texture
	else:
		action_texture.texture = action_interact_texture

func register_boss(boss: BossBase):
	print('Registrating boss:', boss)
	boss_bar.visible = true
	boss.signal_boss_health_changed.connect(rsignal_boss_health_changed)
	boss.signal_boss_health_depleted.connect(rsignal_boss_health_depleted)

func deregister_boss(boss: BossBase):
	print('Deregistrating boss:', boss)
	boss_bar.visible = false
	boss.signal_boss_health_changed.disconnect(rsignal_boss_health_changed)
	boss.signal_boss_health_depleted.disconnect(rsignal_boss_health_depleted)

func rsignal_boss_health_changed(value:int,max:int):
	boss_bar_progress.max_value = max
	boss_bar_progress.value = value

func rsignal_boss_health_depleted():
	pass

func update_health(value: int = 1, max: int = 1):
	if _cache_player_health and _cache_player_health > value:
		$AnimationPlayer.play("hit")
	_cache_player_health = value
	_cache_player_max_health = max
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
		var icon = heart_node.get_child(0)
		if shield_active:
			if hp_in_heart == 2:
				icon.texture = heart_full_shield_texture
			elif hp_in_heart == 1:
				icon.texture = heart_half_shield_texture
			else:
				icon.texture = heart_empty_shield_texture
		else:
			if hp_in_heart == 2:
				icon.texture = heart_full_texture
			elif hp_in_heart == 1:
				icon.texture = heart_half_texture
			else:
				icon.texture = heart_empty_texture

func update_equipped_weapon(weapon: Lookup.WeaponType):
	weapon_texture.texture = Lookup.get_weapon_texture(-1, weapon)

func show_title(str: String):
	var scene = title.instantiate()
	scene.set_text(str)
	add_child(scene)

func update_coins(amount: int):
	coin_label.text = 'Coins: ' + str(amount)

func update_shield(is_active: bool):
	shield_active = is_active
	update_health(_cache_player_health, _cache_player_max_health)

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

func rsignal_player_room_cleared():
	$AnimationPlayer.play_backwards("room_enter")

func rsignal_player_room_changed(r: RoomBase):
	if r.room_state != 2 and not r.is_peaceful_room:
		$AnimationPlayer.play("room_enter")

func _on_button_pressed() -> void:
	pass # Replace with function body.
