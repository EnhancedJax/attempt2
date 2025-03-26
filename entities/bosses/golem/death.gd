extends State

@export var animated_sprite : AnimatedSprite2D

func enter() -> void:
	animated_sprite.play("death")
	p.weapon_node.queue_free()
	p.weapon_node = null
	p.disable()
