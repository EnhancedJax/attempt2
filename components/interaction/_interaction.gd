class_name InteractionComponent extends Area2D

signal signal_player_entered
signal signal_player_exited

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print('Player entered')
		emit_signal("signal_player_entered")


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		print('Player exited')
		emit_signal("signal_player_exited")
