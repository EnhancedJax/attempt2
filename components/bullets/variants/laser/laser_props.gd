class_name LaserBulletProps
extends BulletProps

@export_category("Laser properties")
## Width of laser. If collide_at_impact is true, at the impact points, it will create collision shape of radius of the width.
@export var laser_width : float = 1
## If laser speed is set, laser will expand (towards direction) at that speed to the collision point.
@export var laser_speed: float = -1 # instant
## If true, laser collides at impact points instead of the whole laser
@export var collide_at_impact : bool = false
@export var laser_fill_gradient : Gradient
## How long the laser stays active.
@export var time_laser_active : float = -1 # one frame
## If true, laser only fades out after calling laser_stop(). Overrides time_laser_active.
@export var external_control_disable : bool = false
## How long the laser takes to fade out.
@export var time_laser_fade : float = 1.0 # TOOD: Implement
@export var laser_pierce_count : int = -1 # infinite pierce
var bullet_scene = preload("res://components/bullets/variants/laser/laser.tscn")
