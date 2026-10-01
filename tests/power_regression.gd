extends SceneTree
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",text)
func settle(frames: int=3) -> void:
	for i in frames: await physics_frame
func run() -> void:
	var room=load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	room.join_player(100);room.join_player(101);room.join_player(102)
	var player=room.players[0]
	var ally=room.players[1]
	check(not player.try_power(),"Power unavailable in lobby")
	room.encounter.begin()
	for enemy in room.encounter.enemies: enemy.set_physics_process(false)
	var heart=room.encounter.enemies[0]
	var rootling=room.encounter.enemies[1]
	heart.position=Vector3(0,0,0)
	rootling.position=Vector3(1.2,0,0)
	for i in range(2,room.encounter.enemies.size()): room.encounter.enemies[i].position=Vector3(18,0,-18-i)
	player.position=Vector3(0,0,5)
	player.last_input=Vector2(1,-1)
	await settle()
	check(player.try_power(),"Ember power starts")
	check(not player.try_power(),"Power cannot bypass cooldown")
	check(player.invulnerability>=0.3,"Dash grants brief protection")
	await settle(15)
	check(player.position.z<3.0,"Ember dash moves through physics")
	check(heart.health==65,"Dash landing deals burst damage")
	room.box(Vector3(5,2,0.4),Vector3(0,1,10),Color.GRAY,true)
	player.position=Vector3(0,0,12)
	player.last_input=Vector2(1,-1)
	player.power_cooldown=0
	await settle()
	player.try_power()
	await settle(15)
	check(player.position.z>10.4,"Dash cannot pass through wall")
	player.position=Vector3(0,0,4)
	player.class_id=1;player.power_cooldown=0
	heart.health=100
	await settle()
	player.try_power()
	var projectiles:=0
	for child in room.encounter.get_children():
		if child.get_script()==load("res://scripts/realm_projectile.gd"):
			projectiles+=1
	check(projectiles==3,"Volley creates three piercing arrows")
	await settle(35)
	check(heart.health<100,"Volley damages a target")
	# Fresh rootling gives a stable snare target after the volley.
	room.encounter.spawn_rootling(Vector3(0,0,2))
	rootling=room.encounter.enemies.back()
	player.class_id=2;player.power_cooldown=0
	player.try_power()
	check(rootling.root_time==2.5,"Spore power applies root duration")
	check(rootling.health==15,"Snare deals initial damage")
	var origin: Vector3=rootling.position
	await settle(20)
	check(rootling.position.distance_to(origin)<0.05,"Snared rootling cannot move")
	player.class_id=3;player.power_cooldown=0;player.health=50
	ally.position=player.position+Vector3(1,0,0)
	ally.invulnerability=0;ally.take_damage(1000)
	player.try_power()
	check(player.health==75,"Sanctuary heals living caster")
	check(not ally.downed and ally.health==40,"Sanctuary revives nearby fallen ally")
	check(player.invulnerability>=1.0,"Sanctuary grants brief protection")
	player.power_cooldown=0
	ally.position=Vector3(18,0,15)
	ally.invulnerability=0;ally.take_damage(1000)
	player.try_power()
	check(ally.downed,"Sanctuary cannot revive a distant ally")
	player.invulnerability=0;player.take_damage(1000)
	player.power_cooldown=0
	check(not player.try_power(),"Downed player cannot cast powers")
	var puppet=player.get_node("GnomePuppet")
	for i in 5: puppet._process(0.1)
	check(puppet.current_clip == "Down","Downed gnome plays skeletal fall")
	check(puppet.scale.is_equal_approx(Vector3.ONE),"Fall preserves full body proportions")
	player.revive()
	for i in 5: puppet._process(0.1)
	check(puppet.current_clip != "Down","Revive leaves the downed animation")
	check(puppet.weapon.kind==3,"Weapon updates with selected class")
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_SHIFT;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	player.power_held=false;player.power_cooldown=0
	player._physics_process(0.016)
	check(player.power_cooldown>0,"Shift press activates realm power")
	player.power_cooldown=0
	player._physics_process(0.016)
	check(player.power_cooldown==0,"Holding Shift cannot auto-repeat power")
	event=InputEventKey.new()
	event.physical_keycode=KEY_SHIFT;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events()
	player._physics_process(0.016)
	# Validate the camera against far-apart existing players, feet and labels.
	player.position=Vector3(-18,0,-16);ally.position=Vector3(18,0,18)
	room.update_camera(10)
	var viewport: Vector2=root.get_visible_rect().size
	var inside:=true
	for pawn in room.players:
		for point in [pawn.position,pawn.position+Vector3.UP*3.8]:
			var screen: Vector2=room.camera.unproject_position(point)
			inside=inside and screen.x>=0 and screen.x<=viewport.x and screen.y>=viewport.y*0.14 and screen.y<=viewport.y*0.82
	check(inside,"Spread camera keeps players clear of HUD")
	room.free()
	await process_frame
	print("POWER RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
