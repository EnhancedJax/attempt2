extends BulletBase

@onready var line : Line2D = $Line2D
@onready var raycast: RayCast2D = $RayCast2D

const MAX_DISTANCE = 1000

func _ready() -> void:
	perform_raycast()

func _process(delta: float) -> void:
	pass	

func perform_raycast() -> void:
	raycast.target_position = ATTACK.towards_vector * MAX_DISTANCE

	# Setup collision area
	var collision_shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(raycast.target_position.length(), 2)
	collision_shape.shape = rectangle
	collision_shape.rotation = ATTACK.towards_vector.angle()
	collision_shape.position = raycast.target_position / 2
	self.add_child(collision_shape)
	
	await get_tree().process_frame
	
	var end_point = raycast.get_collision_point() if raycast.is_colliding() else raycast.target_position
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(end_point))
	
	await get_tree().create_timer(0.1).timeout
	self.queue_free()
