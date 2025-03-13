extends Node2D
@onready var _health : HealthComponent = $HealthComponent
@onready var _hurtbox : Area2D = $HurtboxComponent

func _ready() -> void:
	_hurtbox.connect("signal_hit", rsignal_hitbox_hit)
	_health.connect("signal_health_deducted", rsignal_health_deducted)
	_health.connect("signal_health_depleted", rsignal_health_depleted)

func rsignal_hitbox_hit(attack: AttackBase) -> void:
	_health.take_damage(attack.damage)

func rsignal_health_deducted(health: int, max_health: int) -> void:
	pass

func rsignal_health_depleted():
	queue_free()
