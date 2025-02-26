extends Node2D

# var Room = preload("res://scenes/room_placer.tscn")

# const tile_size = 8
# const num_rooms = 5
# const min_size = 4
# const max_size = 10
# const hspread = 200
# const min_room_distance = 50  # Minimum distance between room centers

# func _ready():
# 	randomize()
# 	make_rooms()
	
# func make_rooms():
# 	var room_positions = []  # Track all room positions
	
# 	for i in range(num_rooms):
# 		var pos = Vector2(randi() % (hspread * 2) - hspread, randi() % (hspread * 2) - hspread)
		
# 		# Check if the new position is too close to any existing room
# 		var too_close = true
# 		var max_attempts = 100  # Prevent infinite loops
# 		var attempts = 0
		
# 		while too_close and attempts < max_attempts:
# 			too_close = false
# 			for existing_pos in room_positions:
# 				if pos.distance_to(existing_pos) < min_room_distance:
# 					too_close = true
# 					pos = Vector2(randi() % (hspread * 2) - hspread, randi() % (hspread * 2) - hspread)
# 					attempts += 1
# 					break
		
# 		room_positions.append(pos)  # Add position to the list
		
# 		var r = Room.instantiate()
# 		var w = min_size + randi() % (max_size - min_size)
# 		var h = min_size + randi() % (max_size - min_size)
# 		r.make_room(pos, Vector2(w, h) * tile_size)
# 		$Rooms.add_child(r)
	
# 	# wait for movement to stop
# 	await get_tree().create_timer(1.1).timeout

# 	# var rooms = $Rooms.get_children()
# 	# rooms.shuffle()  # Randomize the array
# 	# rooms[0].apply_force(Vector2(0, 1))
		
# func _draw():
# 	for room in $Rooms.get_children():
# 		draw_rect(Rect2(room.global_position - room.size, room.size * 2),
# 				 Color(32, 228, 0), false)
				
# func _process(delta):
# 	queue_redraw()
	
# func _input(event):
# 	if event.is_action_pressed('ui_select'):
# 		for n in $Rooms.get_children():
# 			n.queue_free()
# 		make_rooms()
