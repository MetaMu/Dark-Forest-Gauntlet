extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func save(name: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/polish/"+name+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/polish")
	var room=load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	for i in 60: await physics_frame
	await save("lobby")
	room.join_player(100);room.join_player(101);room.join_player(102)
	room.encounter.begin()
	for i in room.players.size():
		room.players[i].position=Vector3(-3+i*2,0.1,12)
	for i in 60: await physics_frame
	await save("party")
	# Capture the six-step puppet cadence during real keyboard movement.
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_D;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	for frame in 12:
		for i in 6: await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/polish/walk_%02d.png" % frame)
	event=InputEventKey.new()
	event.physical_keycode=KEY_D;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events()
	for i in room.players.size():
		room.players[i].position=Vector3(-11+i*1.5,0.1,-8)
	for i in 60: await physics_frame
	for player in room.players: player.try_attack()
	for i in 12: await physics_frame
	await save("combat")
	var hud=null
	for child in room.get_children():
		if child.get_script()==load("res://scripts/game_hud.gd"): hud=child
	hud.toggle_pause()
	await save("pause")
	hud.toggle_pause()
	# Small-window layout check, with the same logical canvas scaling as play.
	root.size=Vector2i(960,540)
	await save("small-window")
	room.free()
	for i in 10: await process_frame
	print("POLISH CAPTURES SAVED")
	quit()
