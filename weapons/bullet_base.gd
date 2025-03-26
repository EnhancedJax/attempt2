class_name BulletBase extends RigidBody2D

@export var SPEED : float
var ATTACK: AttackBase

func _process(delta: float) -> void:
	if $ShadowSprite:
		$ShadowSprite.global_position = global_position + Vector2(0, 8)
		$ShadowSprite.global_rotation = global_rotation

func physics_update(collision: KinematicCollision2D) -> void:
	if collision:
		#var collider = collision.get_collider()
		handle_hit()

# /* ------------- Methods ------------ */

func register_attack(attack: AttackBase) -> void:
	ATTACK = attack

func handle_hit():
	queue_free()

func _disable() -> void:
	self.process_mode = Node.PROCESS_MODE_DISABLED
	$Sprite2D.visible = false
	$ShadowSprite.visible = false
