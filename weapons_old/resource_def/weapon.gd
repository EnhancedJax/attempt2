class_name WeaponResource extends Resource

enum FiringMode {
	AUTO = 0,
	SEMI_AUTO = 1,
	SINGLE_ROUND = 2
}

@export var name : StringName
@export_category("Weapon orientation")
@export var position : Vector2 = Vector2(0, 0)
@export var rotation : float = 0
@export var scale : Vector2 = Vector2(1, 1)
@export_category("Weapon assets")
@export var texture : CompressedTexture2D
@export_category("Weapon firing")
@export var firing_mode : FiringMode = 0
@export var fire_rate : int = 5
@export_category("Weapon audio")
@export var fire_sound : AudioStream
