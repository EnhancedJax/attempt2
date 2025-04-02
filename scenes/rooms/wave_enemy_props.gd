class_name WaveEnemyProps
extends Resource

## Enemy scene to spawn
@export var enemy: PackedScene
## Number of this enemy to spawn
@export var spawn_count: int = 1
## Time to wait before spawning the next enemy
@export var spawn_delay: float = 0
## Explicitly spawn at the center of the room. Default spawns randomly in the room
@export var spawn_at_center: bool = false
## Offset from the center if spawn_at_center is true
@export var spawn_center_offset: Vector2 = Vector2.ZERO
@export_category("Boss")
## If this enemy is a boss
@export var enemy_is_boss: bool = false
## The splash screen to show when spawning this boss
@export var splash_scene: PackedScene
## The music to play when spawning this boss
@export var boss_bgm: String = "boss"