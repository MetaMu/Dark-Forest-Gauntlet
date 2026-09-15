extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func frames(n: int=4) -> void:
	for i in n: await process_frame;await physics_frame
func run() -> void:
	var room=load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room);current_scene=room
	room.enable_keyboard_party();room.select_party_class(0,3)
	room.party.switch_member(0);room.party.switch_member(1)
	var classes:=[]
	for p in room.players: classes.append(p.class_id)
	room.encounter.begin()
	for e in room.encounter.enemies: e.take_damage(10000)
	room.encounter.advance(0)
	check(room.encounter.state==room.encounter.State.REWARD,"Pear appears after clearing level one")
	room.players[0].position=room.encounter.reward_position
	room.encounter.advance(0)
	check(room.transitioning,"Eating the pear initiates travel without the exit gate")
	room.encounter.collect_pear() # Repeated pickup cannot queue a second transition.
	await frames(12)
	room=current_scene
	check(room.level_id==2,"Pear loads the Bellcap Cistern")
	check(room.encounter.state==room.encounter.State.COMBAT,"Level two starts automatically")
	check(room.party!=null and room.players.size()==4,"Keyboard teams survive the transition")
	var restored:=[]
	for p in room.players: restored.append(p.class_id)
	check(restored==classes,"Chosen classes survive the transition")
	check(room.party.active==[1,1],"Both active gnomes survive the transition")
	check(not has_meta("campaign_roster") and not has_meta("campaign_auto_begin"),"Transition metadata is consumed")
	# The first dead anchor schedules a reinforcement wave on the next frame.
	for wave in 3:
		for e in room.encounter.enemies:
			if is_instance_valid(e): e.take_damage(10000)
		await frames()
		room.encounter.advance(0)
	room.encounter.collect_pear()
	check(room.encounter.state==room.encounter.State.EXIT,"Level two pear still opens the final exit")
	for i in room.players.size(): room.players[i].position=Vector3(-1+i*.6,.1,-23)
	room.encounter.advance(0);await frames()
	var hud
	for child in room.get_children():
		if child.get_script()==load("res://scripts/game_hud.gd"): hud=child
	check(hud.celebration.visible and not hud.modal.visible,"Final exit displays Maria's celebration scroll")
	var Scroll=load("res://scripts/victory_scroll.gd")
	check(Scroll.pose_at(.0)==Scroll.pose_at(Scroll.LOOP_SECONDS),"Jump loop returns to exactly the same pose")
	check(Scroll.pose_at(1.2).jump>60.0,"Maria jumps visibly above the floor")
	var used: Dictionary={}
	for tick in 312: used[Scroll.pose_at(float(tick)/100.0).frame]=true
	check(used.size()==50,"Victory sequence visits all fifty generated poses")
	check(Scroll.ATLAS.get_size()==Vector2(3200,1600),"Victory uses the new ten-column five-row atlas")
	check(Scroll.pose_at(.1).frame==0 and Scroll.pose_at(3.1).frame==49,"Opening and closing poses retain their longer holds")
	if "--capture" in OS.get_cmdline_user_args():
		for i in 50:
			hud.celebration.manual_time=1.15+(.06 if i==0 else .12+float(i-1)*.06+.03)
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/celebration/frame-%02d.png"%i)
			if i==9: root.get_texture().get_image().save_png("res://artifacts/celebration/preview.png")
	room.queue_free();await frames()
	print("CAMPAIGN RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
