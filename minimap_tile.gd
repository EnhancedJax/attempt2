extends PanelContainer

const panel_unvisited = preload("res://hud/minimap/unvisited.tres")
const panel_visited = preload("res://hud/minimap/visited.tres")
const panel_current = preload("res://hud/minimap/current.tres")

@export var icon_bank : MinimapIconBank
var style : String = "unvisited"
const should_show_icon_unvisited : Array[Dungen.RoomType] = [Dungen.RoomType.SHOP, Dungen.RoomType.ENTRANCE, Dungen.RoomType.EXIT, Dungen.RoomType.BOSS]

func update_room_type(type: Dungen.RoomType): # might be ran when not ready?!
	var icon = $CenterContainer/Img
	if style == "unvisited" and not should_show_icon_unvisited.has(type):
		icon.texture = null
		return
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
		Dungen.RoomType.BOSS_PREP:
			icon.texture = icon_bank.icon_boss_prep

func update_style(sty: String):
	style = sty
	if sty == "current":
		add_theme_stylebox_override("panel", panel_current)
	if sty == "visited":
		add_theme_stylebox_override("panel", panel_visited)
	elif sty == "unvisited":
		add_theme_stylebox_override("panel", panel_unvisited)
		
