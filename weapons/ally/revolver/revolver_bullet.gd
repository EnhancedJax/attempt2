extends BulletBase

var velocity : Vector2

func _ready() -> void:
	velocity = SPEED * ATTACK.towards_vector.normalized()
	rotation = velocity.angle()
	
func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	physics_update(collision)
