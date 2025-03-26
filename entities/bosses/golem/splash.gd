extends SplashBase

func play():
	await get_tree().create_timer(0.5).timeout
	signal_splash_finished.emit()
	self.queue_free()
