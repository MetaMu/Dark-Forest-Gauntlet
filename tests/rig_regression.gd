extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: ",message)
func run() -> void:
	var room=load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	var actor=room.players[0]
	actor.set_physics_process(false)
	var rig=actor.get_node("GnomePuppet")
	rig.set_process(false)
	for id in 5:
		actor.class_id=id;rig.set_class(id)
		check(rig.skeleton.get_bone_count()==52,"Shared skeleton for class %d" % id)
		for clip in ["Idle","Walk","Attack","Cast","Hit","Down"]:
			check(rig.animation_player.has_animation(clip),"Class %d clip %s" % [id,clip])
		var bone=rig.skeleton.find_bone("thigh.L")
		rig.animation_player.play("Walk");rig.animation_player.seek(0,true)
		var before=rig.skeleton.get_bone_pose_rotation(bone)
		rig.animation_player.seek(.2,true)
		check(not before.is_equal_approx(rig.skeleton.get_bone_pose_rotation(bone)),"Walk moves a skinned leg for class %d" % id)
		check(rig.weapon.get_parent() is BoneAttachment3D,"Equipment uses a bone socket")
	actor.class_id=0;rig.set_class(0)
	actor.downed=true;rig._process(.1)
	check(rig.current_clip=="Down","Downed state selects fall")
	actor.downed=false;rig._process(.1)
	check(rig.current_clip!="Down","Revival leaves fall")
	actor.power_cooldown=7;rig._process(.1)
	check(rig.current_clip=="Cast","Power selects cast")
	room.queue_free();await process_frame;await process_frame
	var cistern=load("res://scenes/bellcap_cistern.tscn").instantiate();root.add_child(cistern);cistern.encounter.begin();await process_frame
	var types: Dictionary={}
	for enemy in cistern.encounter.enemies:
		var key=enemy.enemy_title if not enemy.enemy_title.is_empty() else "ROOTLING"
		if types.has(key): continue
		types[key]=true
		check(enemy.has_combat_clips(),"Combat rig on "+key)
		enemy.take_damage(10000)
		check(enemy.dead and enemy.collision_layer==0,"Death disables "+key)
	check(types.size()==4,"All four enemy types checked")
	for i in 110: await physics_frame
	for enemy in cistern.encounter.enemies:
		if is_instance_valid(enemy) and enemy.dead: check(false,"Corpse failed to expire")
	cistern.free();await process_frame
	print("RIG RESULT: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
