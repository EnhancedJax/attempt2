class_name Player extends EntityBase

var weapons : Array[int] = []
var equipped_weapon_index : int = 0
var max_weapons_count : int = 2
@onready var label : Label = $Label
@onready var label_timeout : Timer = $LabelTimeout
@onready var invincibility_timer: Timer = $InvincibilityTimer

func _ready():
	super._ready()
	Main.register_player(self)
	if equipped_weapon_index + 1 <= weapons.size():
		equip_weapon(weapons[equipped_weapon_index])
	
	invincibility_timer.timeout.connect(func(): is_invincible = false)
	label.visible = false
	label_timeout.timeout.connect(handle_label_timeout)

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.visible = true
		weapon_node.handle_use(delta, false)
	if Input.is_action_just_pressed("switch_weapon"):
		if weapons.size() > 1:
			var next_weapon = (equipped_weapon_index + 1) % weapons.size()
			equip_weapon(weapons[next_weapon])
			equipped_weapon_index = next_weapon

func get_aim_position() -> Vector2:
	return get_global_mouse_position()

func rsignal_weapon_did_use(attack: AttackBase):
	$Camera2D.apply_shake(5)
	self.apply_force(-attack.towards_vector * attack.recoil)

func rsignal_hitbox_hit(attack: AttackBase):
	print('Entity was hit')
	if is_invincible:
		return
	
	# Apply knockback force
	apply_force(attack.towards_vector * attack.knockback)
	_health.take_damage(attack.damage)
	
	# Start brief invincibility
	is_invincible = true
	invincibility_timer.start()

func rsignal_health_deducted(health: int, max_health: int):
	super.rsignal_health_deducted(health, max_health)
	$Camera2D.apply_shake(10)
	Main.update_health()

func equip_weapon(weapon_id: int) -> Lookup.WeaponType:
	var weapon = super.equip_weapon(weapon_id)
	label.visible = true
	label.text = weapon.name
	label_timeout.start()
	return weapon

func handle_label_timeout():
	label.visible = false
	label.text = ""
	label_timeout.stop()

func do_die():
	self.process_mode = Node.PROCESS_MODE_DISABLED

func pickup_weapon(weapon_id: int) -> int:
	"""
	Picks up weapon and returns the weapon that was dropped
	"""
	equip_weapon(weapon_id)
	if weapons.size() == max_weapons_count:
		var dropped_weapon = weapons[equipped_weapon_index]
		weapons.remove_at(equipped_weapon_index)
		weapons.insert(equipped_weapon_index, weapon_id)
		return dropped_weapon
	else:
		weapons.push_back(weapon_id)
		equipped_weapon_index = weapons.size() - 1
		return -1
