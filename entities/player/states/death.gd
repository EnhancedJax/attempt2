extends State
class_name PlayerDeath

@onready var sm: PlayerStateMachine = get_parent()

func enter():
	sm.player.weapon_node.queue_free()
	sm.animatedSprite.play("death")

func _on_animated_sprite_2d_animation_finished() -> void:
	sm.player.process_mode = Node.PROCESS_MODE_DISABLED
