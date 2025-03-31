class_name HurtboxComponent extends Area2D

signal signal_hit(attack: AttackBase)

# New custom class to track damage ticking per body.
class DamageTicker:
	var body: Node2D
	var timer: Timer

	func _init(_body: Node2D, _tick_interval: float, _parent: Node) -> void:
		body = _body
		timer = Timer.new()
		timer.one_shot = false
		timer.wait_time = _tick_interval
		timer.timeout.connect( func() -> void:
			_parent.handle_hit(body)
		)
		_parent.add_child(timer)
		timer.start()

# Replace dictionary with an array of DamageTicker.
var active_damage_tickers: Array[DamageTicker] = []

func _find_ticker(body: Node2D) -> DamageTicker:
	for ticker in active_damage_tickers:
		if ticker.body == body:
			return ticker
	return null

func _on_body_entered(body: Node2D) -> void:
	print('[HURTBOX] Body entered: ', body)
	if "ATTACK" in body:
		handle_hit(body)  # Initial damage tick
		# Only handle continuous ticking if damage_tick_interval > 0.
		if body.ATTACK.damage_tick_interval > 0:
			if _find_ticker(body) == null:
				var ticker = DamageTicker.new(body, body.ATTACK.damage_tick_interval, self)
				active_damage_tickers.append(ticker)

func handle_hit(body: Node2D) -> void:
	signal_hit.emit(body.ATTACK)
	if body.has_method("handle_hit"):
		body.handle_hit()

func _on_body_exited(body: Node2D) -> void:
	# Stop and free the timer if it exists.
	var ticker = _find_ticker(body)
	if ticker:
		ticker.timer.stop()
		ticker.timer.queue_free()
		active_damage_tickers.erase(ticker)
