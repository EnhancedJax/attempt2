class_name Bullet
extends RigidBody2D

signal signal_bullet_collision()
signal signal_bullet_removed()

func initialize(_bullet_data: Variant, _start_rotation: float):
    pass

func handle_hit():
    pass