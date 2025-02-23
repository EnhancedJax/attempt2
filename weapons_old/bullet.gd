extends Node2D

const SPEED: int = 4000
var owner_node: Node2D
var attack: Attack

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "TileMapLayer2":
		queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("do_hit"):
		area.do_hit(attack)
		# queue_free()
