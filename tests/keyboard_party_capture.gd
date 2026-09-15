extends SceneTree
const Controls=preload("res://scripts/local_input.gd")
const OUT="res://artifacts/keyboard-coop/"
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await process_frame
		await RenderingServer.frame_post_draw
func capture(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+file+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	room.enable_keyboard_party();await frames(30);await capture("lobby")
	var hud: Node
	for child in room.get_children():
		if child is CanvasLayer and child.get("keyboard_settings")!=null: hud=child
	hud.toggle_pause();hud.keyboard_settings.show();await frames(3);await capture("controls")
	hud.keyboard_settings.hide();hud.toggle_pause()
	room.encounter.begin()
	for i in 4: room.players[i].position=Vector3(-3+i*2,.1,2)
	for enemy in room.encounter.enemies:
		enemy.position+=Vector3(0,0,5)
	await frames(40)
	Input.action_press(Controls.action_name(-1,"right"));Input.action_press(Controls.action_name(-2,"up"))
	Input.action_press(Controls.action_name(-1,"attack"));Input.action_press(Controls.action_name(-2,"attack"))
	await frames(18)
	Input.action_release(Controls.action_name(-1,"right"));Input.action_release(Controls.action_name(-2,"up"))
	Input.action_press(Controls.action_name(-1,"power"));Input.action_press(Controls.action_name(-2,"power"))
	await frames(12);await capture("combat")
	Input.action_release(Controls.action_name(-1,"power"));Input.action_release(Controls.action_name(-2,"power"))
	Input.action_press(Controls.action_name(-1,"switch"));Input.action_press(Controls.action_name(-2,"switch"))
	await frames(5)
	Input.action_release(Controls.action_name(-1,"switch"));Input.action_release(Controls.action_name(-2,"switch"))
	await frames(20);await capture("switched")
	for device in [-1,-2]:
		for action in Controls.ACTIONS: Input.action_release(Controls.action_name(device,action))
	room.free();await frames(3)
	print("KEYBOARD CAPTURE COMPLETE");quit()
