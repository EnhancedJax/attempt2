extends BossBase

@export var state_machine : StateMachine
var weapon_node_x : float

func _ready() -> void:
	super._ready()
	weapon_node = $Chaingun
	weapon_node_x = weapon_node.position.x

func _process(delta: float) -> void:
	super._process(delta)
	if weapon_node:
		if state_machine.current_state is GolemLaserState:
			return
		weapon_node.update_sprite_flip(get_aim_position())
		weapon_node.visible = true

		if animatedSprite2D.flip_h: 
			weapon_node.position.x = weapon_node_x * -1
		else:
			weapon_node.position.x = weapon_node_x

func do_die():
	pass

func get_aim_position() -> Vector2: 
	var player = Main.player
	if player:
		return player.global_position
	else:
		return Vector2.ZERO
