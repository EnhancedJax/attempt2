extends BulletBase

var velocity : Vector2

func _ready() -> void:
	velocity = SPEED * ATTACK.towards_vector.normalized()
	rotation = velocity.angle()
	
func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	physics_update(collision)

func handle_hit():
	$Sprite2D.visible = false
	$ShadowSprite.visible = false
	$CPUParticles2D.emitting = true
	await get_tree().create_timer(.2).timeout
	self.queue_free()
