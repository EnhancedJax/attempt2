extends Node2D

signal finished()

func _ready() -> void:
	$AnimatedSprite2D.play('default')

func _on_animated_sprite_2d_animation_finished() -> void:
	finished.emit()
	self.queue_free()
