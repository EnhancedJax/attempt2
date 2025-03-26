extends EntityBase

const hit_sound = preload("res://entities/enemies/skeleton/hit.wav")

func _ready():
	super._ready()
	equip_weapon(0)
	$CPUParticles2D.emitting = true

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.visible = true

func rsignal_hitbox_hit(attack: AttackBase):
	super.rsignal_hitbox_hit(attack)
	Main.signal_player_landed_hit.emit()
	SoundManager.play_at_position_varied("skeleton", "hit", global_position, randf_range(0.8,1.2), 2)

func get_aim_position() -> Vector2:
	return Main.player.global_position

func do_die():
	SoundManager.play_at_position_varied("skeleton", "die", global_position, randf_range(0.8,1.2), 2)
