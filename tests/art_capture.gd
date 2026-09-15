extends SceneTree
var room: Node3D
func _initialize() -> void: call_deferred("run")
func save(name: String) -> void:
	for i in 35: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/art-upgrade/"+name+".png")
func run() -> void:
	room=load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	await save("lobby")
	for i in 3:room.join_player(100+i)
	room.encounter.begin()
	for enemy in room.encounter.enemies: enemy.set_physics_process(false)
	await save("entry-party")
	for i in 4:room.players[i].position=Vector3(-3+i*2,.1,5-i*2)
	await save("ruin-walk")
	for i in 4:room.players[i].position=Vector3(-3+i*2,.1,-15-i)
	await save("sanctum")
	room.set_process(false)
	room.camera.position=Vector3(15,18,23);room.camera.look_at(Vector3(0,1,15));room.camera.size=13
	for i in 4:room.players[i].position=Vector3(-2.4+i*1.6,.1,17.4-i*1.6)
	await save("equipment-detail")
	root.size=Vector2i(960,540)
	room.set_process(true)
	await save("small-window")
	print("ART CAPTURES COMPLETE")
	room.free();quit()
