extends PanelContainer

const panel_unvisited = preload("res://hud/minimap/unvisited.tres")
const panel_visited = preload("res://hud/minimap/visited.tres")
const panel_current = preload("res://hud/minimap/current.tres")

func update_text(str: String):
	if str != "E":
		$CenterContainer/Label.text = str
	else:
		$CenterContainer/Label.text = ""

func update_style(sty: String):
	if sty == "current":
		add_theme_stylebox_override("panel", panel_current)
	if sty == "visited":
		add_theme_stylebox_override("panel", panel_visited)
	elif sty == "unvisited":
		add_theme_stylebox_override("panel", panel_unvisited)
		
