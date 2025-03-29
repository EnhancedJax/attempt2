class_name PatternPoints
extends BulletSpawnPattern

@export_group("Points pattern")
## Points to spawn the bullets, relative to spawn position. Amount of bullets * points.size() will be the total amount of bullets
@export var points: Array[Vector2] = []
## The variation of the angle of the bullets randomly
@export var randomized_angle_spread: float = 0.0