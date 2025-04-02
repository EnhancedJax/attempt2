extends RoomBase

var chest : PackedScene = preload("res://scenes/chest/chest.tscn")
var splash : PackedScene = preload("res://entities/bosses/golem/splash.tscn")
var splash_scene : SplashBase

const bgm = preload("res://shared_assets/music/boss.wav")

func handle_clear_room_rewards():
	var chest_scene = chest.instantiate()
	chest_scene.spawned_in_active_room = true
	Main.spawn_node(chest_scene, _get_room_center() + Vector2(0, -64), 3)
	MusicManager.play('bgm', 'bgm', 1.0, true)
