class_name DummyCharacter extends GunUser

func _ready() -> void:
    equip_weapon([BasicGun, preload("res://weapons/rifle.tres")])