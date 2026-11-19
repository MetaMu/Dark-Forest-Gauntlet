extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var room = load("res://scenes/rig_showcase.tscn").instantiate()
	root.add_child(room)
	room.set_process(false)
	for actor in room.actors: actor.get_node("GnomePuppet").set_process(false)
	for i in 4: await process_frame
	var frames := [["Idle",0.0],["Walk",.25],["Run",.18],["Cast",.7],["Cast",1.4],["Cast",2.1]]
	for j in frames.size():
		var shot = frames[j]
		room.caption.text = "%s — %.2f seconds" % shot
		for actor in room.actors:
			var rig=actor.get_node("GnomePuppet")
			rig.rotation.y=0
			rig.sample_clip(shot[0],shot[1])
			rig.update_equipment(shot[0] == "Cast")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/mixamo-locomotion/engine-%02d.png"%j)
	room.free()
	quit()
