extends Node2D

const coin = preload("res://scenes/coin/coin.tscn")

@export var count: int = 1
@export var spawn_radius: int = 15
@export var spawn_delay: float = 0.05

func _ready():
	spawn_coins()

func get_random_circle_position() -> Vector2:
	var angle = randf() * PI * 2  # Random angle between 0 and 2π
	var x = cos(angle) * spawn_radius
	var y = sin(angle) * spawn_radius
	return Vector2(x, y)

func spawn_coins():
	for i in count:
		var coin_instance = coin.instantiate()
		add_child(coin_instance)
		coin_instance.position = get_random_circle_position()
		await get_tree().create_timer(spawn_delay).timeout
