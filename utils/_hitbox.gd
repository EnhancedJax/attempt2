extends Area2D

func do_hit(attack : Attack):
	var parent = get_parent()
	if parent is EntityBase:
		parent.take_attack(attack)
