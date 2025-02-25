class_name Player extends EntityBase

var weapons : Array[PackedScene] = [preload("res://weapons/m15/m_15.tscn")]
var equipped_weapon_index : int = 0

func _ready():
	super._ready()
	Main.register_player(self)
	equip_weapon(weapons[equipped_weapon_index])

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
	if Input.is_action_pressed("fire"):
		weapon_node.handle_use(delta)
	if Input.is_action_just_pressed("switch_weapon"):
		var next_weapon = (equipped_weapon_index + 1) % weapons.size()
		equip_weapon(weapons[next_weapon])
		equipped_weapon_index = next_weapon


func get_aim_position() -> Vector2:
	return get_global_mouse_position()

func rsignal_weapon_did_use(attack: AttackBase):
	$Camera2D.apply_shake(5)
	self.apply_force(-attack.direction * attack.recoil)

# func _on_damage(health, MAX_HEALTH, damage) -> void:
# 	if not is_invincible:
# 		$AnimatedSprite2D/AnimationPlayer.play("RESET")
# 		$AnimatedSprite2D/AnimationPlayer.play("flash")
# 		$Camera2D.apply_shake(10)
# 		$"../CanvasLayer/HUD".update_health(health, MAX_HEALTH)
