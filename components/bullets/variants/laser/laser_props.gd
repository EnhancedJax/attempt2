class_name LaserBulletProps
extends BulletProps

@export_category("Laser properties")
## Width of laser.
@export var laser_width : int = 1
## Damage tick
@export var damage_tick_interval : float = 1.0  
## How long the laser stays active.
@export var time_laser_active : float = -1 # one frame
## If true, laser only fades out after calling laser_stop(). Overrides time_laser_active.
@export var external_control_disable : bool = false
## How long the laser takes to fade out.
@export var time_laser_fade : float = 1.0 
## How much objects does the laser pierce. -1 is infinite until wall
@export var laser_pierce_count : int = -1 # infinite pierce
## Speed at which the laser grows to its maximum width (pixels per second)
@export var animate_width_speed : float = 0.0
## Speed at which the laser extends to its maximum length (pixels per second)
@export var animate_length_speed : float = 0.0
## Continously update laser cast?
@export var continous_cast : bool = false
## Particle effect to display at the origin point of the laser
@export var origin_point_particle : PackedScene
## Particle effect to display along the laser beam body
@export var laser_particle : PackedScene
@export_category("Laser Line2D properties")
## The gradient filling of Line2D.
@export var laser_fill_gradient : Gradient
## The texture used for the laser.
@export var laser_texture : Texture
## Start end cap
@export var line_cap_round : bool = false

var bullet_scene = preload("res://components/bullets/variants/laser/laser.tscn")
