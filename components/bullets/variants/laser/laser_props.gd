class_name LaserBulletProps
extends BulletProps

@export_category("Laser properties")
## Width of laser.
@export var laser_width : int = 1
## The gradient filling of Line2D.
@export var laser_fill_gradient : Gradient
## How long the laser stays active.
@export var time_laser_active : float = -1 # one frame
## If true, laser only fades out after calling laser_stop(). Overrides time_laser_active.
@export var external_control_disable : bool = false
## How long the laser takes to fade out.
@export var time_laser_fade : float = 1.0 
## How much objects does the laser pierce. -1 is infinite until wall
@export var laser_pierce_count : int = -1 # infinite pierce
## Damage tick
@export var damage_tick_interval : float = 1.0  
## Speed at which the laser grows to its maximum width (pixels per second)
@export var animate_width_speed : float = 0.0
## Speed at which the laser extends to its maximum length (pixels per second)
@export var animate_length_speed : float = 0.0
## Particle effect to display at the origin point of the laser
@export var origin_point_particle : PackedScene
## Particle effect to display along the laser beam body
@export var laser_particle : PackedScene

var bullet_scene = preload("res://components/bullets/variants/laser/laser.tscn")
