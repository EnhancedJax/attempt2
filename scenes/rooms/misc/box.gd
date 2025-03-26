extends StaticBody2D
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
	$Sprite2D.visible = false
	self.set_collision_layer_value(4, false)
	self.set_collision_mask_value(4, false)
	_hurtbox.queue_free()
	$CPUParticles2D.emitting = true
	await get_tree().create_timer(1).timeout
	queue_free()
