class_name Player extends EntityBase

var weapons : Array[PackedScene] = []
var equipped_weapon_index : int = 0
var invincibility_timer: Timer

func _ready():
	super._ready()
	Main.register_player(self)
	if equipped_weapon_index + 1 <= weapons.size():
		equip_weapon(weapons[equipped_weapon_index])
	
	# Setup invincibility timer
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(func(): is_invincible = false)
	add_child(invincibility_timer)

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.handle_use(delta, false)
	if Input.is_action_just_pressed("switch_weapon"):
		if weapons.size() > 0:
			var next_weapon = (equipped_weapon_index + 1) % weapons.size()
			equip_weapon(weapons[next_weapon])
			equipped_weapon_index = next_weapon


func get_aim_position() -> Vector2:
	return get_global_mouse_position()

func rsignal_weapon_did_use(attack: AttackBase):
	$Camera2D.apply_shake(5)
	self.apply_force(-attack.towards_vector	 * attack.recoil)

func rsignal_hitbox_hit(attack: AttackBase):
	print('Entity was hit')
	if is_invincible:
		return
	
	# Apply knockback force
	apply_force(attack.towards_vector * attack.knockback)
	_health.take_damage(attack.damage)
	
	# Start brief invincibility
	is_invincible = true
	invincibility_timer.start(0.1)

func rsignal_health_deducted(health: int, max_health: int):
	super.rsignal_health_deducted(health, max_health)
	$Camera2D.apply_shake(10)
	Main.update_health()

func do_die():
	self.process_mode = Node.PROCESS_MODE_DISABLED
