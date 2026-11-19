extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/mixamo-locomotion/video-frames"))
	var room=load("res://scenes/rig_showcase.tscn").instantiate()
	root.add_child(room);room.set_process(false)
	var camera:Camera3D
	for child in room.get_children():
		if child is Camera3D:camera=child
	for actor in room.actors:actor.get_node("GnomePuppet").set_process(false)
	for frame in 450:
		var time=frame/30.0
		var clip="Walk"
		var local_time=time
		var angle=0.0
		var label="MIXAMO WALK · all five original gnome skins"
		if time>=3 and time<6:clip="Run";local_time=time-3;label="MIXAMO RUN · preserved airborne phase"
		elif time>=6 and time<8.7:clip="Cast";local_time=time-6;label="STANDING 2H MAGIC ATTACK 01 · free-hand cast"
		elif time>=8.7 and time<10.2:clip="Run";local_time=time-8.7;angle=PI/2;label="MIXAMO RUN · side view"
		elif time>=10.2 and time<12.9:clip="Cast";local_time=time-10.2;angle=PI/2;label="2H MAGIC ATTACK 01 · side view"
		elif time>=12.9:clip="Walk";local_time=time-12.9;label="PALM GRIP · Spore Grove staff"
		room.caption.text=label
		for actor in room.actors:
			var rig=actor.get_node("GnomePuppet")
			rig.rotation.y=angle
			var duration=rig.animation_player.get_animation(clip).length
			rig.sample_clip(clip,minf(local_time,duration) if clip=="Cast" else fmod(local_time,duration))
			rig.update_equipment(clip=="Cast")
		if time>=12.9:
			var actor=room.actors[3]
			var rig=actor.get_node("GnomePuppet")
			var hand=rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("hand.R")).origin
			camera.size=.9;camera.position=hand+Vector3(0,.15,1);camera.look_at(hand)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/mixamo-locomotion/video-frames/frame-%04d.png"%frame)
	room.free();quit()
