extends State
class_name SkeletonDeath

var friction : float = 1000.0

func enter():
	p = sm.parent
	sm.parent.weapon_node.queue_free()
	if sm.animator:
		sm.animator.play("RESET")
		sm.animator.play("death")
	sm.animatedSprite.stop()

	p.disable()
	p.velocity = p.extra_velocity * 4
	
func physics_update(delta: float) -> void:
	# Apply friction to slow down the sliding
	p.velocity = p.velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Handle collisions before moving
	var collision = p.move_and_collide(p.velocity * delta)
	if collision:
		# Add some extra bounce force
		p.velocity = p.velocity.bounce(collision.get_normal()) * 0.8
