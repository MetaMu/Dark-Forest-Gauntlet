extends SceneTree

var failures := 0
var report := {"captures": [], "checks": []}

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, description: String) -> void:
	report.checks.append({"passed": ok, "description": description})
	print("PASS: " if ok else "FAIL: ", description)
	if not ok:
		failures += 1

func capture(room, filename: String) -> void:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/gnome-trial/" + filename)
	verify(result == OK, "Saved " + filename)
	report.captures.append(filename)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/gnome-trial")
	var room = load("res://scenes/gnome_sprite_trial.tscn").instantiate()
	root.add_child(room)
	for i in 60:
		await physics_frame
	var player = room.players[0]
	verify(room.gnome.texture.get_size() == Vector2(2048,512), "Imported four-view texture dimensions")
	verify(room.gnome.no_depth_test == false, "Sprite participates in scene depth")
	# Local bottom pixel is -208; offset +208 anchors the soles to node origin.
	verify(room.gnome.offset.y == 208, "Foot pixel maps to player origin")
	report["world_height"] = room.SPRITE_HEIGHT
	report["camera_size"] = room.camera.size
	report["viewport"] = str(root.size)
	for view in 4:
		room.gnome.frame = view
		await capture(room, "view_%d.png" % view)
	var start: Vector3 = player.position
	var event := InputEventKey.new()
	event.physical_keycode = KEY_D
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	for i in 30:
		await physics_frame
	event = InputEventKey.new()
	event.physical_keycode = KEY_D
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	verify(player.position.distance_to(start) > 1.0, "Player moves with sprite attached")
	await capture(room, "movement.png")
	player.take_damage(100)
	await process_frame
	await process_frame
	verify(player.downed and is_equal_approx(room.gnome.scale.y,0.3), "Sprite follows downed state")
	player.revive()
	await process_frame
	await process_frame
	verify(not player.downed and is_equal_approx(room.gnome.scale.y,1.0), "Sprite restores on revive")
	# Place behind the entry-grove plinth relative to the camera.
	player.position = Vector3(6.6,0.05,13.6)
	for i in 90:
		await physics_frame
	await capture(room, "occlusion.png")
	report["failures"] = failures
	var file := FileAccess.open("res://artifacts/gnome-trial/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	quit(failures)
