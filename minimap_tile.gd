extends PanelContainer

const panel_unvisited = preload("res://hud/minimap/unvisited.tres")
const panel_visited = preload("res://hud/minimap/visited.tres")
const panel_current = preload("res://hud/minimap/current.tres")

@export var icon_bank : MinimapIconBank

func update_text(str: String): # might be ran when not ready?!
	var icon = $CenterContainer/Img
	match str:
		"E":
			icon.texture = icon_bank.icon_enemy
		"B":
			icon.texture = icon_bank.icon_beginning
		"F":
			icon.texture = icon_bank.icon_finish
		"L":
			icon.texture = icon_bank.icon_loot
		"S":
			icon.texture = icon_bank.icon_shop

func update_style(sty: String):
	if sty == "current":
		add_theme_stylebox_override("panel", panel_current)
	if sty == "visited":
		add_theme_stylebox_override("panel", panel_visited)
	elif sty == "unvisited":
		add_theme_stylebox_override("panel", panel_unvisited)
		
