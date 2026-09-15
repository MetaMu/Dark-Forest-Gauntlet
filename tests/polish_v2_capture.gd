extends SceneTree
func _initialize() -> void: call_deferred("run")
func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/polish-v2/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/polish-v2")
	var room=load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	room.join_player(100);room.join_player(101);room.join_player(102)
	room.encounter.begin()
	for enemy in room.encounter.enemies: enemy.set_physics_process(false)
	for i in 4:
		room.players[i].position=Vector3(-3+i*2,0.1,5-i*2)
	for i in 40: await physics_frame
	await save("weapons")
	for player in room.players:
		player.attack_windup=0.5;player.pending_attack=true
		player.get_node("GnomePuppet")._process(0.1)
	await save("windup")
	for i in 25: await physics_frame
	await save("release")
	room.players[0].take_damage(1000)
	for i in 25: await physics_frame
	await save("downed")
	room.players[3].position=room.players[0].position+Vector3(1.3,0,1)
	room.players[3].try_power()
	await save("sanctuary")
	for i in 30: await physics_frame
	await save("revived")
	root.size=Vector2i(960,540)
	await save("small-window")
	room.free()
	for i in 8: await process_frame
	print("V2 CAPTURES SAVED")
	quit()
