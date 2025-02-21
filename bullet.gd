extends Node2D

const SPEED: int = 4000

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta


func _on_area_2d_body_entered(body: Node2D) -> void:
	print(body)
	queue_free()
