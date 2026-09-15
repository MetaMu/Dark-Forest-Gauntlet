extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await process_frame
		await RenderingServer.frame_post_draw
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/level-two/"+name+".png")
func run() -> void:
	var room=load("res://scenes/bellcap_cistern.tscn").instantiate();root.add_child(room)
	room.enable_keyboard_party();await frames(20);await shot("lobby")
	room.encounter.begin();room.set_process(false)
	room.camera.position=Vector3(28,43,33);room.camera.look_at(Vector3(0,0,-1));room.camera.size=57
	await frames(10);await shot("floor-plan")
	for i in 4: room.players[i].position=Vector3(10+i*1.1,.1,-1)
	room.camera.position=Vector3(31,25,16);room.camera.look_at(Vector3(13,0,-5));room.camera.size=22
	await frames(135);await shot("mortar-warning")
	await frames(85);await shot("spore-pool")
	room.queue_free();await frames(5);print("LEVEL TWO CAPTURES COMPLETE");quit()
