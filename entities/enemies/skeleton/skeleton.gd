extends EntityBase

func _ready():
	super._ready()
	equip_weapon(0)

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.visible = true

func get_aim_position() -> Vector2:
	return Main.player.global_position
