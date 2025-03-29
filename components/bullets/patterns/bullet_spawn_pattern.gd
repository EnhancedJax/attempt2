class_name BulletSpawnPattern
extends Resource

## Flat speed of bullet
@export var speed = 400.0
## Amount of bullets each fire
@export var amount_of_bullets : int = 1
## Time between each bullet spawn
@export var time_between_bullets : float = 0.0
## Time before the bullet starts moving
@export var time_before_move : float = 0.0
## TIme between each bullets before it starts moving
@export var time_between_bullets_before_move : float = 0.0
## Time between each fire (after previous fire finishes)
@export var time_between_fire : float = 0.5
