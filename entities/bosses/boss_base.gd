class_name BossBase extends EntityBase

signal signal_boss_health_deducted(value: int, max: int)
signal signal_boss_health_depleted()

func _ready() -> void:
	super._ready()
	Main.register_boss(self)

func _on_health_deducted(health: int, max_health: int):
	signal_boss_health_deducted.emit(health, max_health)
	super._on_health_deducted(health, max_health)

func _on_health_depleted():
	signal_boss_health_depleted.emit()
	Main.deregister_boss(self)
	super._on_health_depleted()
