class_name Attack extends Resource

var damage: int = 0
var recoil: float = 0  # Force applied to the shooter
var knockback: float = 0  # Force applied to the target
var direction: Vector2 = Vector2.ZERO  # Direction of the attack
var source: Node = null  # Who fired the attack