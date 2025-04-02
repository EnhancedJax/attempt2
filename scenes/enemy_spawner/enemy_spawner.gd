class_name EnemySpawner
extends Node2D


var node: Node2D


func _on_timer_timeout() -> void:
	Main.spawn_node(node, self.global_position, 3)


func _on_animated_sprite_2d_animation_finished() -> void:
	self.queue_free()
