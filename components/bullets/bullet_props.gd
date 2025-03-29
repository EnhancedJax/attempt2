class_name BulletProps
extends Resource

@export var damage : float = 1.0
@export var knockback_magnitude : float = 100.0
@export var sprite_texture : CompressedTexture2D
@export var should_rotate : bool = true
@export var hit_particle : PackedScene
@export var has_shadow : bool = true
@export var life_time : int = 30
@export var is_player_bullet : bool = false
@export var bullet_pierce_count : int = 0
@export var bullet_bounce_count : int = 0
@export var bullet_modulate : Color = Color(2,2,2,1) # slight glow by default
# trailing etc.
