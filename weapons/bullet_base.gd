class_name BulletBase extends Node2D

@export var SPEED : float
var ATTACK: AttackBase

func _ready() -> void:
	$Area2D.connect("body_entered", rsignal_body_entered)
	$Area2D.connect("area_entered", rsignal_area_entered)

# /* ------------- Methods ------------ */

func register_attack(attack: AttackBase) -> void:
	ATTACK = attack

func handle_hitbox_entered(area: Area2D) -> void:
	print(ATTACK.towards_vector)
	area.hit(ATTACK)
	queue_free()

# /* ------------ Interals ------------ */

func rsignal_body_entered(body: Node2D) -> void:
	if body.name == "TileMapLayer2":
		queue_free()

func rsignal_area_entered(area: Area2D) -> void:
	print('entered area', area)
	if area.has_method("hit"):
		handle_hitbox_entered(area)
