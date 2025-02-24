class_name BulletBase extends Node2D

var SPEED : float
var ATTACK: AttackBase

func _ready() -> void:
	connect("body_entered", rsignal_body_entered)
	connect("area_entered", rsignal_area_entered)

# /* ------------- Methods ------------ */

func handle_hitbox_entered(area: Area2D) -> void:
		area.do_hit(ATTACK)
		queue_free()

# /* ------------ Interals ------------ */

func rsignal_body_entered(body: Node2D) -> void:
	if body.name == "TileMapLayer2":
		queue_free()

func rsignal_area_entered(area: Area2D) -> void:
	if area.has_method("do_hit"):
		handle_hitbox_entered(area)
