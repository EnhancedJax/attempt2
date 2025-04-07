class_name Route extends Resource

@export var name : String
@export var scene : PackedScene
@export var subroutes: Array[Route]
@export var is_root: bool = false