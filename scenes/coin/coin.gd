extends Node2D

var speed := 0.0
var acceleration := 200.0
var max_speed := 300.0

func _process(delta: float) -> void:
	var direction = (Main.player.global_position - global_position).normalized()
	speed = min(speed + acceleration * delta, max_speed)
	position += direction * speed * delta

func rsignal_body_entered(body: Node2D) -> void:
	if body is Player:
		Main.update_coins(1)
		SoundManager.play("coin", "pickup")
		queue_free() # Destroy coin after collection
