extends PanelContainer

const panel_unvisited = preload("res://hud/minimap/unvisited.tres")
const panel_visited = preload("res://hud/minimap/visited.tres")
const panel_current = preload("res://hud/minimap/current.tres")

@export var icon_bank : MinimapIconBank

func update_text(type: Dungen.RoomType): # might be ran when not ready?!
	var icon = $CenterContainer/Img
	match type:
		Dungen.RoomType.ENEMY:
			icon.texture = icon_bank.icon_enemy
		Dungen.RoomType.ENTRANCE:
			icon.texture = icon_bank.icon_beginning
		Dungen.RoomType.EXIT:
			icon.texture = icon_bank.icon_finish
		Dungen.RoomType.LOOT:
			icon.texture = icon_bank.icon_loot
		Dungen.RoomType.SHOP:
			icon.texture = icon_bank.icon_shop
		Dungen.RoomType.BOSS:
			icon.texture = icon_bank.icon_boss

func update_style(sty: String):
	if sty == "current":
		add_theme_stylebox_override("panel", panel_current)
	if sty == "visited":
		add_theme_stylebox_override("panel", panel_visited)
	elif sty == "unvisited":
		add_theme_stylebox_override("panel", panel_unvisited)
		
