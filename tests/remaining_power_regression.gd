extends "res://tests/power_design_capture.gd"
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func run() -> void:
	var spore:=await stage(2)
	spore.position=Vector3(0,.1,1)
	var target=room.encounter.enemies[0];target.position=Vector3.ZERO
	for i in range(1,room.encounter.enemies.size()): room.encounter.enemies[i].position=Vector3(16+i,0,-15)
	spore.try_power();spore.advance_cast(spore.CAST_RELEASE);await frame(2)
	var roots=target.get_node_or_null("RootSnareVFX")
	check(roots!=null,"Snare attaches roots to an eligible target")
	check(roots.root_materials.size()==10,"Five roots have separate bark and violet growth materials")
	check(roots.root_materials[0].get_shader_parameter("growth")<1,"Root growth begins before the complete shape is revealed")
	await frame(28)
	check(roots.root_materials[0].get_shader_parameter("growth")==1.0,"Roots finish growing while the status is active")
	check(get_nodes_in_group("spore_motes").size()>0,"Active roots release drifting spores")
	check(get_nodes_in_group("spore_motes").size()<=4,"Persistent spore emission is bounded per target")
	target.position+=Vector3.RIGHT
	await frame(2)
	check(roots.global_position.is_equal_approx(target.global_position),"Roots remain attached when their target moves")
	target.root_time=0;target.slow_time=.5;await frame(2)
	check(not roots.root_geometry.visible,"Roots disappear when the root status ends")
	target.slow_time=0;await frame(3)
	check(not is_instance_valid(roots),"Target effects clear when both statuses end")
	await clear_stage()
	var light:=await stage(3,3)
	light.position=Vector3(-.7,.1,1);light.health=65
	var ally=room.players[1];ally.position=Vector3(-2,.1,2.3);ally.health=40
	var downed=room.players[2];downed.position=Vector3(0,.1,3);downed.invulnerability=0;downed.take_damage(1000)
	var distant=room.players[3];distant.position=Vector3(15,.1,15);distant.health=40
	light.try_power();light.advance_cast(light.CAST_RELEASE);await frame(3)
	check(light.health==90 and ally.health==65,"Sanctuary retains its healing on release")
	check(not downed.downed,"Sanctuary revives the eligible fallen ally")
	check(distant.health==40,"Distant ally remains unaffected")
	check(get_nodes_in_group("healing_halos").size()==3,"Halos appear only on the three eligible allies")
	check(get_nodes_in_group("healing_pulses").size()==3,"Each eligible ally receives a traveling healing pulse")
	await frame(25)
	check(get_nodes_in_group("healing_pulses").is_empty(),"Healing pulses expire after reaching their recipients")
	await frame(55)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Sanctuary clears instead of implying a persistent healing zone")
	light.power_cooldown=0;light.try_power();light.advance_cast(light.CAST_RELEASE);await frame(2)
	room.encounter.finish(room.encounter.State.WON);await frame(4)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Encounter completion clears sanctuary and attached halos")
	await clear_stage()
	print("REMAINING POWERS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
