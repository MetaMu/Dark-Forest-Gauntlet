extends "res://tests/power_design_capture.gd"
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func run() -> void:
	var player:=await stage(0)
	player.try_power();player.advance_cast(player.CAST_RELEASE)
	await frame(2)
	var ghosts:=get_nodes_in_group("ember_afterimages")
	check(not ghosts.is_empty(),"Rig dash creates a visible afterimage")
	var ghost: Node3D=ghosts[0]
	var meshes:=ghost.find_children("*","MeshInstance3D",true,false)
	check(not meshes.is_empty(),"Afterimage contains baked character geometry")
	var stationary:=ghost.global_position
	var all_static:=true
	for mesh in meshes:
		if mesh.skin!=null: all_static=false
	check(all_static,"Afterimage is independent of the live skeleton")
	await frame(6)
	check(ghost.global_position.is_equal_approx(stationary),"Snapshot stays behind while the player dashes")
	check(get_nodes_in_group("ember_afterimages").size()==3,"One dash emits exactly three pose snapshots")
	var wakes:=0
	for fx in get_nodes_in_group("realm_vfx"):
		if fx.mode=="ember_wake": wakes+=1
	check(wakes>0 and wakes<=12,"Flame wake has bounded distance-based emission")
	await frame(90)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Landing, smoke, ghosts and sparks all expire")
	player.power_cooldown=0;player.try_power();player.advance_cast(player.CAST_RELEASE);await frame(3)
	room.encounter.finish(room.encounter.State.WON);await frame(4)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Encounter end clears an active Ember cast")
	await clear_stage()
	print("EMBER RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
