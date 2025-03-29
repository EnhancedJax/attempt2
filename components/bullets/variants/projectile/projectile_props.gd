class_name ProjectileBulletProps
extends BulletProps

@export_category("Projectile properties")
@export var sprite_texture : CompressedTexture2D
@export var should_rotate : bool = true
@export var has_shadow : bool = true
@export var life_time : int = 30
@export var bullet_pierce_count : int = 0
@export var bullet_bounce_count : int = 0
# trailing etc.
var bullet_scene = preload("res://components/bullets/variants/projectile/projectile.tscn")
