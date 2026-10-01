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
	await settle()
	var player=room.players[0]
	room.select_class(-1,1)
	check(player.class_id==1,"Lobby class selection changes player")
	room.join_player(100);room.join_player(101);room.join_player(102)
	check(room.players.size()==4,"Four sprite players join")
	check(room.players[3].get_node("GnomePuppet").skeleton.get_bone_count()==52,"Gnomes have the shared articulated 3D skeleton")
	room.encounter.begin()
	room.select_class(-1,3)
	check(player.class_id==1,"Class selection locks during combat")
	for enemy in room.encounter.enemies:
		enemy.set_physics_process(false)
	var heart=room.encounter.enemies[0]
	# Test in open ground away from the authored obstacle rows.
	heart.position=Vector3(0,0,0)
	for i in range(1,room.encounter.enemies.size()):
		room.encounter.enemies[i].position=Vector3(18,0,-16-i)
	player.position=Vector3(0,0,5)
	player.set_physics_process(false)
	await settle()
	check(player.try_attack(),"Ranger attack begins windup")
	check(heart.health==100 and player.pending_attack,"Windup delays damage")
	player._physics_process(0.13)
	check(not player.pending_attack,"Windup releases attack")
	await settle(30)
	check(heart.health==78,"Ranger projectile deals 22 damage at range")
	check(not player.try_attack(),"Ranger cannot bypass cooldown")
	player.class_id=0
	player.position=Vector3(0,0,2)
	room.encounter.attack(player)
	check(heart.health==58,"Ember sweep deals nearby damage")
	player.position=Vector3(0,0,7)
	room.encounter.attack(player)
	check(heart.health==58,"Ember cannot hit outside melee range")
	player.class_id=2
	player.position=Vector3(0,0,4)
	room.encounter.attack(player)
	await settle(2)
	check(heart.slow_time>0 and heart.health<58,"Spore cloud damages and applies slow")
	for i in 5: room.encounter.attack(player)
	check(room.encounter.clouds.size()==3,"Spore cloud population is bounded")
	player.class_id=3
	player.health=90
	var ally=room.players[1]
	ally.health=70;ally.position=player.position+Vector3(1,0,0)
	var distant=room.players[2]
	distant.health=70;distant.position=Vector3(15,0,12)
	room.encounter.attack(player)
	check(player.health==94 and ally.health==74,"Light heals self and nearby ally")
	check(distant.health==70,"Light does not heal a distant ally")
	player.health=99;room.encounter.attack(player)
	check(player.health==100,"Healing never exceeds maximum health")
	ally.downed=true;ally.health=0
	room.encounter.attack(player)
	check(ally.health==0 and ally.downed,"Healing does not bypass revive interaction")
	ally.downed=false;ally.health=100
	player.invulnerability=0;player.take_damage(1000)
	check(player.downed and not player.pending_attack,"Downing cancels pending attacks")
	player.revive()
	check(player.health==40 and not player.downed,"Revive restores the sprite player")
	# A wall must block a direct class target query.
	room.box(Vector3(3,2,0.5),Vector3(0,1,2),Color.GRAY,true)
	await settle()
	check(not room.encounter.visible_to(Vector3(0,0,4),Vector3.ZERO),"Class attacks respect obstacle line of sight")
	var hud=null
	for child in room.get_children():
		if child.get_script()==load("res://scripts/game_hud.gd"): hud=child
	hud.toggle_pause()
	check(paused,"Pause menu pauses simulation")
	hud.toggle_pause()
	check(not paused,"Pause menu resumes simulation")
	for enemy in room.encounter.enemies:
		if is_instance_valid(enemy): enemy.take_damage(1000)
	room.encounter.advance(0)
	check(room.encounter.state==room.encounter.State.REWARD,"Polished encounter produces reward")
	player.position=room.encounter.reward_position
	room.level_id=2 # Shared gate behavior; level one's automatic travel is tested separately.
	room.encounter.advance(0)
	check(room.encounter.state==room.encounter.State.EXIT,"Reward opens gate")
	for pawn in room.players:
		pawn.position=Vector3(0,0,-23)
	room.encounter.advance(0)
	check(room.encounter.state==room.encounter.State.WON,"Full surviving party completes polished encounter")
	room.free()
	await process_frame
	print("REALM RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
