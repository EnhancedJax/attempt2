extends RigidBody2D

@onready var sprite : Sprite2D = $Sprite2D
@export var ATTACK: AttackBase

func _ready() -> void:
	pass

func register(radius :float, build_time :float, attack_time : float, attack_towards: Vector2) -> void:
	ATTACK.towards_vector = attack_towards
	var collision_shape = CollisionShape2D.new()
	collision_shape.scale.y = 0.7
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	await get_tree().create_timer(build_time).timeout
	add_child(collision_shape)
	await get_tree().create_timer(attack_time).timeout
	self.queue_free()
