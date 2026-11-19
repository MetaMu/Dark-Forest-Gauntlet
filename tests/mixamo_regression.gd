extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if ok: print("PASS: ",message)
	else: failures+=1;push_error(message)
func run()->void:
	var room=load("res://scenes/rig_showcase.tscn").instantiate()
	root.add_child(room);room.set_process(false)
	for actor in room.actors:
		var rig=actor.get_node("GnomePuppet")
		rig.set_process(false)
		var id=actor.class_id
		check(rig.animation_player.has_animation("Run"),"Class %d imports real run"%id)
		check(rig.animation_player.get_animation("Cast").length>2.6,"Class %d retains complete magic performance"%id)
		for clip in ["Walk","Run"]:
			var anim=rig.animation_player.get_animation(clip)
			var bone=rig.skeleton.find_bone("thigh.L")
			rig.sample_clip(clip,0)
			var start=rig.skeleton.get_bone_pose_rotation(bone)
			rig.sample_clip(clip,anim.length-.00001)
			check(start.angle_to(rig.skeleton.get_bone_pose_rotation(bone))<.01,"%s loop seam class %d"%[clip,id])
		actor.velocity=Vector3(2,0,0);rig.action_remaining=0;rig._process(.2)
		check(rig.current_clip=="Run","Speed selects run class %d"%id)
		var leg=rig.skeleton.find_bone("thigh.L")
		var before=rig.skeleton.get_bone_pose_rotation(leg)
		rig._process(1.0/120.0)
		check(before.angle_to(rig.skeleton.get_bone_pose_rotation(leg))>.0001,"Motion advances between old 12fps ticks class %d"%id)
		actor.power_cooldown=6;rig._process(1.0/60.0);rig._process(.3)
		check(rig.current_clip=="Cast" and rig.action_remaining>2.0,"Cast is not truncated at old .8s class %d"%id)
		before=rig.skeleton.get_bone_pose_rotation(leg);rig._process(.12)
		check(before.angle_to(rig.skeleton.get_bone_pose_rotation(leg))>.01,"Moving cast keeps animated legs class %d"%id)
		if id!=4:
			check(rig.weapon.get_parent()==rig.back_socket,"Two-handed spell stows weapon class %d"%id)
			actor.downed=true;rig._process(.2)
			check(rig.weapon.get_parent()==rig.hand_socket,"Interrupted cast restores weapon class %d"%id)
			check(rig.weapon.transform.is_equal_approx(rig.grip_transform),"Grip frame stays fixed class %d"%id)
			actor.downed=false;rig._process(.1)
			check(rig.current_clip!="Down","Revival cancels interrupted cast lock class %d"%id)
	room.free();await process_frame
	print("MIXAMO RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
