extends BossBase

var weapon_node_x : float

func _ready() -> void:
	super._ready()
	weapon_node = $Chaingun
	weapon_node_x = weapon_node.position.x

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.visible = true

		if animatedSprite2D.flip_h: 
			weapon_node.position.x = weapon_node_x * -1
		else:
			weapon_node.position.x = weapon_node_x

	
# func rsignal_hitbox_hit(attack: AttackBase):
# 	super.rsignal_hitbox_hit(attack)

# 	_show_damage_number(attack.damage)
