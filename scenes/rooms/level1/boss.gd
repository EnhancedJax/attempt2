extends RoomBase

var chest : PackedScene = preload("res://scenes/chest/chest.tscn")
var splash : PackedScene = preload("res://entities/bosses/golem/splash.tscn")
var splash_scene : SplashBase

const bgm = preload("res://shared_assets/music/boss.wav")

func _ready() -> void:
	super._ready()
	splash_scene = splash.instantiate()

func start_wave():
	print(splash)
	MusicManager.play('bgm', 'boss', 1.0, true)
	var boss: EntityBase = enemy_scenes[0].instantiate()
	boss.connect("signal_death", rsignal_spawned_enemy_died)
	get_tree().root.add_child(splash_scene)
	splash_scene.play()
	await splash_scene.signal_splash_finished
	Main.spawn_node(boss, _get_room_center(), 3)

func handle_clear_room_rewards():
	var chest_scene = chest.instantiate()
	chest_scene.spawned_in_active_room = true
	Main.spawn_node(chest_scene, _get_room_center() + Vector2(0, -64), 3)
	MusicManager.play('bgm', 'bgm', 1.0, true)
