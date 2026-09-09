extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var room = load("res://scenes/corrupted_clearing.tscn").instantiate()
	root.add_child(room)
	room.join_player(100)
	room.join_player(101)
	room.join_player(102)
	room.encounter.begin()
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var error := root.get_texture().get_image().save_png("res://artifacts/first-playable.png")
	print("Capture result: ", error)
	quit(error)
