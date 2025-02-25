extends Node2D

@onready var floor: TileMapLayer = $Map/Floor
const DUNGEON_GEN = preload("res://dungeon_generator.gd")

func _ready() -> void:
	var dungeon_gen = DUNGEON_GEN.new()
	dungeon_gen.floor = floor
	dungeon_gen.generate_dungeon()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var dungeon_gen = DUNGEON_GEN.new()
		dungeon_gen.floor = floor
		dungeon_gen.generate_dungeon()
