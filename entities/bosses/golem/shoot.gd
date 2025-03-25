extends State

@export var PROJECTILE : PackedScene
@export var ATTACK: AttackBase
@export var fire_rate : float = 15 # bullets per second
@export var random_spread : float = 30.0 # angles
@export var fire_duration : float = 3 # seconds

var fire_timer : float = 0.0
var firing : bool = false
var cooldown_timer : float = 0.0

func enter() -> void:
	sm.animatedSprite.play("shoot")
	firing = true
	fire_timer = fire_duration
	cooldown_timer = 0.0

func update(delta: float) -> void:
	var attack_towards = (Main.player.global_position - p.global_position).normalized()
	if firing:
		fire_timer -= delta
		cooldown_timer -= delta
		if fire_timer <= 0:
			firing = false
		elif cooldown_timer <= 0:
			_spawn_bullet(attack_towards)
			cooldown_timer = 1.0 / fire_rate
	else:
		sm.on_child_transition(self, "Hostile")

func physics_update(delta: float):
	p.velocity = p.velocity.move_toward(Vector2.ZERO, p.FRICTION * delta)    
	p.physics_update(delta)

func _spawn_bullet(attack_towards: Vector2):
	var spread_angle = randf_range(-random_spread, random_spread)
	var rotated_vector = attack_towards.rotated(deg_to_rad(spread_angle))
	var atk = ATTACK.duplicate()
	atk.towards_vector = rotated_vector
	var bullet = PROJECTILE.instantiate()
	bullet.register_attack(atk)
	bullet.rotation = rotated_vector.angle()
	Main.spawn_node(bullet, p.global_position)
