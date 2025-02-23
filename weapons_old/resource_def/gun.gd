class_name Gun extends WeaponResource

@export_category("Gun properties")
@export var magazine : int = 30
@export var reload_speed : int = 1
@export var spread : int = 0
@export_category("Gun attack")
@export var damage : int = 1
@export var recoil : float = 100.0
@export var knockback : float = 200.0
@export_category("Gun 2D")
@export var bullet_spawn : Vector2 = Vector2(0, 0)
