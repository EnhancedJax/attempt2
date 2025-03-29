class_name LaserBulletProps
extends BulletProps

@export_category("Laser properties")
@export var laser_width : float = 0.5
@export var laser_fill_gradient : Gradient
@export var time_laser_active : float = -1 # one frame
@export var time_laser_reach_collision: float = -1 # one frame
@export var time_laser_fade : float = 1.0 # TOOD: Implement
@export var laser_pierce_count : int = -1 # infinite pierce
# trailing etc.
var bullet_scene = preload("res://components/bullets/variants/laser/laser.tscn")