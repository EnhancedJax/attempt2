extends BulletBase

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
