extends RigidBody2D

var size

#func _ready():
	#make_room(Vector2(100,100), Vector2(40,10))

func make_room(pos: Vector2, size: Vector2):
	print("Making room at ", pos, " with size ", size)
	position = pos
	self.size = size
	var s = RectangleShape2D.new()
	s.extents = size
	$CollisionShape2D.shape = s
