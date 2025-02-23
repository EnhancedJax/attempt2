class_name Player extends GunUser

var weapons : Array[Array] = [[BasicGun, preload("res://weapons/rifle.tres")], [BasicGun, preload("res://weapons/pistol.tres")]]
var equipped_weapon_index : int = 0

func _ready():
	equip_weapon(weapons[equipped_weapon_index])

func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("switch_weapon"):
		var next_weapon = (equipped_weapon_index + 1) % weapons.size()
		equip_weapon(weapons[next_weapon])
		equipped_weapon_index = next_weapon
			

func on_weapon_fired():
	$Camera2D.apply_shake(5)

func get_aim_position() -> Vector2:
	return get_global_mouse_position()

# func _on_damage(health, MAX_HEALTH, damage) -> void:
# 	if not is_invincible:
# 		$AnimatedSprite2D/AnimationPlayer.play("RESET")
# 		$AnimatedSprite2D/AnimationPlayer.play("flash")
# 		$Camera2D.apply_shake(10)
# 		$"../CanvasLayer/HUD".update_health(health, MAX_HEALTH)
