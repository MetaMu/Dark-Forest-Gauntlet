extends SceneTree
const VFX=preload("res://scripts/realm_vfx.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	check(VFX.STUDIO_VFX_REVISION=="2026-09-14-crystal-wake-1","Runtime contains the repaired Studio revision")
	var world:=Node3D.new();root.add_child(world);world.position=Vector3(3,0,-4)
	var bolt:=Node3D.new();world.add_child(bolt);bolt.position=Vector3(10,1,10)
	var trail=VFX.projectile_trail(world,bolt,Color.GREEN)
	for i in 26:
		bolt.position.x+=.1
		await process_frame
	var visible:=0;var late_visible:=0;var all_near:=true;var crystals:=0
	for part in trail.parts:
		if part.node.visible:
			visible+=1
			if part.delay>.18: late_visible+=1
			all_near=all_near and part.node.global_position.distance_to(bolt.global_position)<2.0
		if part.node.is_in_group("spell_crystals"): crystals+=1
	check(visible>0,"Glints remain visible after the original 0.18-second failure point")
	check(late_visible>0,"New glints use their own emission time")
	check(all_near and visible>0,"Glints follow an off-origin projectile under a translated parent")
	check(crystals>0,"Moving projectiles emit actual faceted wake geometry")
	check(trail.parts.size()<20,"Short projectile wake has bounded particle allocation")
	bolt.queue_free();await frames(20)
	check(not is_instance_valid(trail),"Projectile trail and wake expire after the projectile disappears")
	VFX.snare_cast(world,Vector3(12,0,8));await frames(5)
	var shards=get_nodes_in_group("spell_crystals")
	check(shards.size()==10,"Spore cast creates a three-crystal heart and seven orbiting shards")
	check(not shards.is_empty() and shards[0].mesh.get_faces().size()==36,"Crystals have closed twelve-triangle faceted geometry")
	var depth_tested:=true
	for shard in shards: depth_tested=depth_tested and not shard.material_override.no_depth_test
	check(depth_tested,"Crystals retain world depth testing")
	await frames(55)
	check(get_nodes_in_group("spell_crystals").is_empty(),"Spore crystal geometry expires with its cast")
	world.queue_free();await frames(3)
	check(get_nodes_in_group("realm_vfx").is_empty(),"Scene cleanup removes all Studio effects")
	print("STUDIO VFX RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
