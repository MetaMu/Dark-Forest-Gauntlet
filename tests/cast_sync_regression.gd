extends SceneTree
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func run()->void:
	for id in 4:
		var room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
		room.select_class(-1,id);room.encounter.begin()
		for enemy in room.encounter.enemies:
			enemy.set_physics_process(false);enemy.health=10000
		var actor=room.players[0];actor.set_physics_process(false);actor.invulnerability=100;actor.health=50
		var rig=actor.get_node("GnomePuppet");rig.set_process(false)
		var events:Array=[]
		actor.power_requested.connect(func(p):events.append({"time":p.cast_elapsed,"pose":rig.clip_time,"origin":rig.cast_origin()}))
		check(actor.try_power(),"Class %d begins charge"%id)
		check(events.is_empty() and actor.dash_time==0 and actor.health==50,"No gameplay effect on button press %d"%id)
		check(not actor.try_attack(),"Basic attack cannot interrupt unreleased charge %d"%id)
		actor.advance_cast(.6);rig._process(0);actor.cast_charge._process(0)
		var charge=actor.cast_charge
		check(charge.hands[0].global_position.distance_to(rig.hand_world("L"))<.001,"Charge follows posed hand %d"%id)
		var low=charge.lamp.light_energy
		var aim=actor.cast_direction;actor.last_input=-aim
		actor.advance_cast(.59);rig._process(0);charge._process(0)
		check(events.is_empty(),"No release before marker %d"%id)
		check(charge.lamp.light_energy>low,"Light builds with the cast clock %d"%id)
		check(actor.power_aim()==aim,"Movement does not turn the committed spell aim %d"%id)
		actor.advance_cast(.02)
		check(events.size()==1,"Exactly one release on marker crossing %d"%id)
		check(is_equal_approx(events[0].time,actor.CAST_RELEASE) and is_equal_approx(events[0].pose,actor.CAST_RELEASE),"Gameplay and pose share exact release marker %d"%id)
		check(not actor.pending_power and actor.cast_charge==null,"Charge clears at release %d"%id)
		if id==0:check(actor.dash_time>0,"Ember starts dash at release")
		if id==1:
			var bolts=room.encounter.find_children("*","Node3D",false,false).filter(func(n):return n.get_script()==load("res://scripts/realm_projectile.gd"))
			check(bolts.size()==3 and bolts[0].global_position.distance_to(events[0].origin)<.001,"Volley originates at posed hands")
		if id==3:check(actor.health==75,"Sanctuary heals at release")
		actor.advance_cast(4)
		check(events.size()==1,"Large frame/recovery cannot fire twice %d"%id)
		actor.power_cooldown=0;actor.try_power();actor.invulnerability=0;actor.take_damage(1)
		actor.advance_cast(3)
		check(events.size()==1 and not actor.pending_power,"Hit cancels unreleased power %d"%id)
		check(actor.power_cooldown<=.75,"Interrupted charge refunds remaining cooldown %d"%id)
		actor.power_cooldown=0;actor.try_power();room.encounter.finish(room.encounter.State.WON);actor.advance_cast(3)
		check(events.size()==1 and actor.cast_charge==null,"Encounter end cancels charge immediately %d"%id)
		await process_frame;await RenderingServer.frame_post_draw
		room.queue_free();await process_frame;await process_frame
	check(get_nodes_in_group("cast_charges").is_empty() and get_nodes_in_group("power_lights").is_empty(),"No charge or light survives scene teardown")
	print("CAST SYNC RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
