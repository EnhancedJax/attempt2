extends Node

var player : Player
var camera : PlayerCamera

func register_player(p : Player) -> void:
	player = p

func register_camera(c : PlayerCamera) -> void:
	camera = c
