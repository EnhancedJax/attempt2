extends RoomBase

const bgm = preload("res://shared_assets/music/boss.wav")

func start_wave():
	MusicManager.play('bgm', 'boss', 5.0, true)
