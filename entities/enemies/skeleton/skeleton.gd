extends EntityBase

const hit_sound = preload("res://entities/enemies/skeleton/hit.wav")

func _ready():
	super._ready()
	equip_weapon(0)

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.visible = true

func rsignal_hitbox_hit(attack: AttackBase):
	super.rsignal_hitbox_hit(attack)
	Main.signal_player_landed_hit.emit()
	SoundManager.play_sound(hit_sound)

func get_aim_position() -> Vector2:
	return Main.player.global_position
