class_name BulletProps
extends Resource

@export_category("Bullet Properties")
@export var damage : int = 1
@export var knockback_magnitude : float = 100.0
@export var is_player_bullet : bool = false
@export var bullet_modulate : Color = Color(2,2,2,1) # slight glow by default
@export var hit_particle : PackedScene