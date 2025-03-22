class_name Player extends EntityBase

# Inventory: each element is the weapon ID. If the same ID appears twice, the player owns two separate instances.
var weapons : Array[int] = [0, 2]
var equipped_weapon_index : int = 0
var max_weapons_count : int = 2

var is_holding_down_fire : bool = false
var is_just_pressed_fire : bool = false
var _can_hold_down_fire : bool = true

@onready var label : Label = $Label
@onready var label_timeout : Timer = $LabelTimeout
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var reload_progress_bar: ProgressBar = $ReloadIndicator/ProgressBar
@onready var shield_timer : Timer = $ShieldTimer

# Changed: cache for weapon nodes as an array wherein each slot corresponds to an inventory slot.
var weapon_nodes: Array[WeaponBase] = []

# Reference to the currently active weapon node.
var reload_duration: float = 0
var reload_timer: float = 0
var is_reloading: bool = false

var last_aiming_at : Vector2 = Vector2.ZERO
var is_dead : bool = false
var is_shield_active : bool = true

signal signal_weapon_equipped()
signal signal_player_death()

func _ready():
	super._ready()
	Main.register_player(self)
	# Ensure there is a valid equipped weapon
	if equipped_weapon_index < weapons.size():
		equip_weapon(weapons[equipped_weapon_index])
	
	invincibility_timer.timeout.connect(func(): is_invincible = false)
	label.visible = false
	label_timeout.timeout.connect(handle_label_timeout)
	shield_timer.timeout.connect(handle_shield_timeout)
	reload_progress_bar.visible = false

func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	if weapon_node:
		var aim_pos = get_aim_position()
		weapon_node.update_sprite_flip(aim_pos)
		
		if is_reloading:
			reload_timer += delta
			var progress = (reload_timer / reload_duration) * 100
			reload_progress_bar.value = progress
			
			if reload_timer >= reload_duration:
				is_reloading = false
				reload_progress_bar.value = 0
				reload_progress_bar.visible = false
				weapon_node.call_finish_reload()

	if Input.is_action_just_pressed("fire"):
		if Main.interactions.size() > 0:
			Main.interactions[0].callable.call()
			_can_hold_down_fire = false
		else:
			is_just_pressed_fire = true
	elif Input.is_action_just_released("fire"):
		is_just_pressed_fire = false
		_can_hold_down_fire = true
	if Input.is_action_pressed("fire"):
		if _can_hold_down_fire:
			is_holding_down_fire = true
	else:
		is_holding_down_fire = false
	if Input.is_action_just_pressed("switch_weapon"):
		if weapons.size() > 1:
			var next_weapon = (equipped_weapon_index + 1) % weapons.size()
			equipped_weapon_index = next_weapon
			equip_weapon(weapons[equipped_weapon_index])
	if Input.is_action_just_pressed("reload"):
		if weapon_node and weapon_node.can_reload:
			weapon_node.call_reload()

func get_aim_position() -> Vector2:
	if Main.player_autoaim_target:
		last_aiming_at = Main.player_autoaim_target.global_position
	else:
		var input_vector = Input.get_vector("left", "right", "up", "down")
		if input_vector != Vector2.ZERO:
			last_aiming_at = input_vector.normalized() * 1000 + self.global_position
	
	if is_reloading:
		# During reload, project last aiming at to horizontal line
		var direction = (last_aiming_at - self.global_position)
		return self.global_position + Vector2(direction.x, 0).normalized() * 1000
	
	return last_aiming_at

func rsignal_weapon_did_use(attack: AttackBase):
	_update_ui_ammo()
	apply_force(-attack.towards_vector * attack.recoil)

func rsignal_weapon_reloading(duration: float):
	is_reloading = true
	reload_duration = duration
	reload_timer = 0
	reload_progress_bar.visible = true
	reload_progress_bar.value = 0
	label.visible = false
	label_timeout.stop()

func rsignal_weapon_did_reload():
	_update_ui_ammo()
	label.visible = true
	label_timeout.start()

func rsignal_hitbox_hit(attack: AttackBase):
	if is_invincible:
		return
	
	# Apply knockback force
	apply_force(attack.towards_vector * attack.knockback)
	
	Main.camera.apply_shake(15)

	# Handle shield mechanic
	if is_shield_active:
		$CPUParticles2D.emitting = true
		is_shield_active = false
		shield_timer.start()
		Main.update_shield_ui(false)
		animationPlayer.play("take_attack")
	else:
		shield_timer.start()
		_health.take_damage(attack.damage)
		# Start brief invincibility
		is_invincible = true
		invincibility_timer.start()
	

func rsignal_health_deducted(health: int, max_health: int):
	super.rsignal_health_deducted(health, max_health)
	Main.update_health_ui()

# Overrides base class implementation
# This function now uses the equipped_weapon_index to cache/reuse a weapon node.
func equip_weapon(weapon_id: int) -> Lookup.WeaponType:
	if is_reloading and weapon_node:
		weapon_node.call_stop_reload()
		is_reloading = false
		reload_progress_bar.visible = false
		reload_progress_bar.value = 0
	
	var weapon = Lookup.get_weapon(weapon_id, is_ally)
	
	# If a previous weapon is equipped, disable its node.
	if weapon_node:
		weapon_node.visible = false
	
	# Use the node found in the corresponding inventory slot if it exists.
	if equipped_weapon_index < weapon_nodes.size() and weapon_nodes[equipped_weapon_index] != null:
		weapon_node = weapon_nodes[equipped_weapon_index]
		weapon_node.visible = true
	else:
		# Instantiate weapon node and save it in the same index as the inventory slot.
		weapon_node = weapon.scene.instantiate()
		weapon_node.connect("signal_weapon_did_use", rsignal_weapon_did_use)
		weapon_node.connect("signal_weapon_reloading", rsignal_weapon_reloading)
		weapon_node.connect("signal_weapon_did_reload", rsignal_weapon_did_reload)
		weapon_node.position = weaponOrigin.position
		weapon_node.visible = true
		add_child(weapon_node)
		# Save or extend the weapon_nodes array to ensure we store this node per inventory slot.
		if equipped_weapon_index < weapon_nodes.size():
			weapon_nodes[equipped_weapon_index] = weapon_node
		else:
			weapon_nodes.append(weapon_node)
	
	# update UI and label
	label.visible = true
	label.text = weapon.name
	label_timeout.start()
	Main.signal_player_equipped_weapon.emit(weapon_node)
	Main.update_equipped_weapon_ui(weapon)
	_update_ui_ammo()
	return weapon

func handle_label_timeout():
	label.visible = false
	label.text = ""
	label_timeout.stop()

func handle_shield_timeout():
	is_shield_active = true
	$ShieldRegenerationParticle2D.emitting = true
	shield_timer.stop()
	Main.update_shield_ui(true)

func do_die():
	if !is_dead:
		is_dead = true
		signal_player_death.emit()

func pickup_weapon(weapon_id: int) -> int:
	"""
	Picks up a weapon and returns the weapon that was dropped.
	"""
	if weapons.size() == max_weapons_count:
		var dropped_weapon = weapons[equipped_weapon_index]
		weapons.remove_at(equipped_weapon_index)
		# Insert the new weapon in the same slot.
		weapons.insert(equipped_weapon_index, weapon_id)
		# If the dropped weapon held a node, free it.
		if equipped_weapon_index < weapon_nodes.size():
			if weapon_nodes[equipped_weapon_index]:
				weapon_nodes[equipped_weapon_index].queue_free()
				weapon_nodes[equipped_weapon_index] = null
		equip_weapon(weapon_id)
		return dropped_weapon
	else:
		weapons.push_back(weapon_id)
		equipped_weapon_index = weapons.size() - 1
		equip_weapon(weapon_id)
		return -1

func _update_ui_ammo():
	Main.update_ammo_ui(weapon_node.mag_count, weapon_node.mag_size)
