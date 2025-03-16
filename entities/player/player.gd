class_name Player extends EntityBase

var weapons : Array[int] = [0, 1]
var equipped_weapon_index : int = 0
var max_weapons_count : int = 2
@onready var label : Label = $Label
@onready var label_timeout : Timer = $LabelTimeout
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var reload_progress_bar: ProgressBar = $ReloadIndicator/ProgressBar
@onready var shield_timer : Timer = $ShieldTimer
var weapon_nodes: Dictionary[int, WeaponBase] = {} # new: cache for weapon nodes
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
	if equipped_weapon_index + 1 <= weapons.size():
		equip_weapon(weapons[equipped_weapon_index])
	
	invincibility_timer.timeout.connect(func(): is_invincible = false)
	label.visible = false
	label_timeout.timeout.connect(handle_label_timeout)
	shield_timer.timeout.connect(handle_shield_timeout)
	reload_progress_bar.visible = false

func _process(delta: float) -> void:
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
	if Input.is_action_just_pressed("switch_weapon"):
		if weapons.size() > 1:
			var next_weapon = (equipped_weapon_index + 1) % weapons.size()
			equip_weapon(weapons[next_weapon])
			equipped_weapon_index = next_weapon
	if Input.is_action_just_pressed("reload"):
		if weapon_node and weapon_node.can_reload:
			weapon_node.call_reload()

func get_aim_position() -> Vector2:
	var closest_enemy = Main.find_closest_enemy(self.global_position)
	if closest_enemy:
		last_aiming_at = closest_enemy.global_position
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
	Main.camera.apply_shake(5)
	apply_force(-attack.towards_vector * attack.recoil)

func rsignal_weapon_reloading(duration: float):
	is_reloading = true
	reload_duration = duration
	reload_timer = 0
	reload_progress_bar.visible = true
	reload_progress_bar.value = 0

func rsignal_hitbox_hit(attack: AttackBase):
	if is_invincible:
		return
	
	# Apply knockback force
	apply_force(attack.towards_vector * attack.knockback)

	# Handle shield mechanic
	if is_shield_active:
		is_shield_active = false
		shield_timer.start()
		Main.update_shield_ui(false)
		animationPlayer.play("take_attack")
	else:
		_health.take_damage(attack.damage)
		# Start brief invincibility
		is_invincible = true
		invincibility_timer.start()
	

func rsignal_health_deducted(health: int, max_health: int):
	super.rsignal_health_deducted(health, max_health)
	Main.camera.apply_shake(10)
	Main.update_health_ui()

func equip_weapon(weapon_id: int) -> Lookup.WeaponType:
	if is_reloading:
		weapon_node.call_stop_reload()
		is_reloading = false
		reload_progress_bar.visible = false
		reload_progress_bar.value = 0
	
	var weapon = Lookup.get_weapon(weapon_id, is_ally)
	if weapon_node:
		# disable current weapon instead of unloading
		weapon_node.visible = false
		# weapon_node.set_process(false)
	
	# reuse cached weapon node if exists; otherwise, instantiate and cache it.
	if weapon_id in weapon_nodes:
		weapon_node = weapon_nodes[weapon_id]
		weapon_node.visible = true
		# weapon_node.set_process(true)
	else:
		weapon_node = weapon.scene.instantiate()
		weapon_node.connect("signal_weapon_did_use", rsignal_weapon_did_use)
		weapon_node.connect("signal_weapon_reloading", rsignal_weapon_reloading)
		weapon_node.position = weaponOrigin.position
		weapon_node.visible = false
		add_child(weapon_node)
		weapon_nodes[weapon_id] = weapon_node
		weapon_node.visible = true
		# weapon_node.set_process(true)
	
	# update UI and label
	label.visible = true
	label.text = weapon.name
	label_timeout.start()
	Main.signal_player_equipped_weapon.emit(weapon_node)
	Main.update_equipped_weapon_ui(weapon)
	return weapon

func handle_label_timeout():
	label.visible = false
	label.text = ""
	label_timeout.stop()

func handle_shield_timeout():
	is_shield_active = true
	shield_timer.stop()
	Main.update_shield_ui(true)

func do_die():
	if !is_dead:
		is_dead = true
		signal_player_death.emit()

func pickup_weapon(weapon_id: int) -> int:
	"""
	Picks up weapon and returns the weapon that was dropped
	"""
	if weapons.size() == max_weapons_count:
		var dropped_weapon = weapons[equipped_weapon_index]
		weapons.remove_at(equipped_weapon_index)
		weapons.insert(equipped_weapon_index, weapon_id)
		# if dropped weapon has a cached node, unload it since it is being dropped
		if dropped_weapon in weapon_nodes:
			weapon_nodes[dropped_weapon].queue_free()
			weapon_nodes.erase(dropped_weapon)
		equip_weapon(weapon_id)
		return dropped_weapon
	else:
		weapons.push_back(weapon_id)
		equipped_weapon_index = weapons.size() - 1
		equip_weapon(weapon_id)
		return -1
