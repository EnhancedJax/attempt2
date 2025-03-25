extends State

@export var animated_sprite : AnimatedSprite2D
@export var melee_attack : PackedScene
@export var RADIUS : float
@export var BUILD_TIME : float = 0.6
@export var ATTACK_TIME : float = 0.3

var build_timer : float = 0.0
var attacked : bool = false

func enter() -> void:
	attacked = false
	var player = Main.player
	var melee_attack_instance = melee_attack.instantiate()
	Main.spawn_node(melee_attack_instance, player.global_position)
	var attack_towards = (player.global_position - p.global_position).normalized()
	melee_attack_instance.register(RADIUS, BUILD_TIME, ATTACK_TIME, attack_towards)
	animated_sprite.play("melee")

func update(delta: float) -> void:
	build_timer += delta
	if build_timer >= BUILD_TIME and not attacked:
		build_timer = 0.0  # Reset build timer to prevent repeated attacks
		attacked = true
		await get_tree().create_timer(ATTACK_TIME).timeout
		sm.on_child_transition(self, "Hostile")

func physics_updawdte(delta: float):
	p.velocity = p.velocity.move_toward(Vector2.ZERO, p.FRICTION * delta)    
	p.physics_update(delta)

func exit() -> void:
	pass
