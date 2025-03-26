extends SplashBase

func play():
	await get_tree().create_timer(1.6).timeout
	signal_splash_finished.emit()
	self.queue_free()
	signal_splash_finished.emit()
