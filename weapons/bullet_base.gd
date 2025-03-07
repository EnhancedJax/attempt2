class_name BulletBase extends RigidBody2D

@export var SPEED : float
var ATTACK: AttackBase

func _process(delta: float) -> void:
	$ShadowSprite.global_position = global_position + Vector2(0, 80)
	$ShadowSprite.global_rotation = global_rotation

func physics_update(collision: KinematicCollision2D) -> void:
	if collision:
		var collider = collision.get_collider()
		#if collider is TileMapLayer:
		queue_free()

# /* ------------- Methods ------------ */

func register_attack(attack: AttackBase) -> void:
	ATTACK = attack

func handle_hit():
	queue_free()
