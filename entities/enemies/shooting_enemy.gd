extends Node2D
class_name ShootingEnemy

var player: Node2D
var health: int = 3

func _ready():
	player = get_tree().get_first_node_in_group("player")
	# Configure the gun for auto-fire
	$GunWeapon.auto_fire = true

func get_aim_position() -> Vector2:
	if player:
		return player.global_position
	return global_position

func on_weapon_fired():
	# Optional: Add effects when the enemy fires
	pass

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

func _process(delta: float) -> void:
	pass
