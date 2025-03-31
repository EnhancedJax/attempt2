class_name LaserBulletProps
extends BulletProps

@export_category("Laser properties")
## Width of laser. 
@export var laser_width : int = 1
## The gradient filling of line2D
@export var laser_fill_gradient : Gradient
## How long the laser stays active.
@export var time_laser_active : float = -1 # one frame
## If true, laser only fades out after calling laser_stop(). Overrides time_laser_active.
@export var external_control_disable : bool = false
## How long the laser takes to fade out.
@export var time_laser_fade : float = 1.0 # TOOD: Implement
@export var laser_pierce_count : int = -1 # infinite pierce
@export var damage_tick_interval : float = 1.0  # New property for continuous damage ticking
var bullet_scene = preload("res://components/bullets/variants/laser/laser.tscn")
