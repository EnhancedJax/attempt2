class_name State extends Node

@onready var sm: StateMachine = get_parent()
var p

signal signal_transitioned

func _ready() -> void:
	p = sm.get_parent()

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func update(_delta: float) -> void:
	pass
