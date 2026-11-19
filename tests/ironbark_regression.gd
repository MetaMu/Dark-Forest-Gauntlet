extends "res://tests/power_design_capture.gd"
const Projectile=preload("res://scripts/realm_projectile.gd")
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func bolts() -> Array:
	var result:=[]
	for child in room.encounter.get_children():
		if child.get_script()==Projectile: result.append(child)
	return result
func run() -> void:
	var player:=await stage(1)
	player.try_power();player.advance_cast(player.CAST_RELEASE)
	check(bolts().size()==3,"Volley creates three projectiles")
	var directions:=[]
	for bolt in bolts(): directions.append(bolt.direction)
	check(directions.size()==3 and directions[0]!=directions[1] and directions[1]!=directions[2],"Streaks follow three distinct firing directions")
	await frame(6)
	check(get_nodes_in_group("ironbark_leaves").size()>0,"Moving volley emits real leaf geometry")
	check(get_nodes_in_group("ironbark_leaves").size()<=72,"Leaf emission is bounded across three streaks")
	for bolt in bolts(): bolt.free()
	for fx in get_nodes_in_group("realm_vfx"): fx.free()
	for i in room.encounter.enemies.size():
		var enemy=room.encounter.enemies[i]
		enemy.position=Vector3(-.5+i*2,0,1) if i<3 else Vector3(15,0,-15)
		enemy.health=1000;enemy.max_health=1000
	var bolt=Projectile.new();bolt.encounter=room.encounter
	bolt.position=Vector3(-3,.7,1);bolt.direction=Vector3.RIGHT
	bolt.damage=25;bolt.remaining_hits=3;bolt.speed=20;bolt.lifetime=.7
	room.encounter.add_child(bolt);bolt.set_physics_process(false)
	for i in 8:
		if is_instance_valid(bolt) and not bolt.is_queued_for_deletion(): bolt._physics_process(.05)
		await frame(1)
	var correct:=true
	for i in 3: correct=correct and room.encounter.enemies[i].health==975
	check(correct,"One piercing bolt deals exactly 25 damage to each of three targets")
	check(get_nodes_in_group("ironbark_impacts").size()==3,"Each confirmed piercing hit emits its own splinter burst")
	check(get_nodes_in_group("ironbark_splinters").size()==27,"Three impacts produce bounded splinter geometry")
	check(not is_instance_valid(bolt),"Projectile expires after its third hit")
	await frame(90)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Trails, leaves and splinters expire after firing stops")
	player.power_cooldown=0;player.try_power();player.advance_cast(player.CAST_RELEASE);await frame(3)
	room.encounter.finish(room.encounter.State.WON);await frame(4)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Encounter completion clears an active volley")
	await clear_stage()
	print("IRONBARK RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
