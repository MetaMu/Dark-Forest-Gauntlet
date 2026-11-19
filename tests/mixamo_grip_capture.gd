extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(640,480)
	var room=load("res://scenes/rig_showcase.tscn").instantiate();root.add_child(room);room.set_process(false)
	var camera:Camera3D
	for child in room.get_children():
		if child is Camera3D:camera=child
	for actor in room.actors:actor.get_node("GnomePuppet").set_process(false)
	for actor in room.actors:
		if actor.class_id==4:continue
		var rig=actor.get_node("GnomePuppet")
		for shot in [["Walk",.25],["Run",.18],["Attack",.35]]:
			rig.sample_clip(shot[0],shot[1]);rig.update_equipment(false)
			await process_frame
			var hand=rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("hand.R")).origin
			camera.size=.6
			for view in 3:
				var angle=view*PI/2
				camera.position=hand+Vector3(sin(angle),.18,cos(angle));camera.look_at(hand)
				room.caption.text="%s %s / view %d"%[rig.IDS[actor.class_id],shot[0],view]
				await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/mixamo-locomotion/grip-%d-%s-%d.png"%[actor.class_id,shot[0],view])
	room.free();quit()
