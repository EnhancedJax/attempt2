extends State

func physics_update(delta: float):
	p.velocity = p.velocity.move_toward(Vector2.ZERO, p.FRICTION * delta)    
	p.physics_update(delta)
