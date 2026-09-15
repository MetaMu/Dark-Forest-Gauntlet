extends SceneTree
const Bomb=preload("res://scripts/spore_bomb.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func frames(n: int=3) -> void:
	for i in n: await physics_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func run() -> void:
	var room=load("res://scenes/bellcap_cistern.tscn").instantiate();root.add_child(room)
	room.enable_keyboard_party();await frames()
	check(room.level_id==2 and room.players.size()==4,"Level two supports both keyboard teams")
	for point in [Vector3(-16,0,-9),Vector3(15,0,-5),Vector3(0,0,-14),Vector3(0,0,-17)]:
		var route: PackedVector3Array=room.route_to(Vector3(0,0,16),point)
		check(not route.is_empty() and route[-1].distance_to(point)<1.5,"Entry reaches objective at %s"%point)
	room.encounter.begin();var encounter=room.encounter
	check(encounter.count_enemies(true)==3 and encounter.count_enemies(false)==8,"Three anchors and eight mobile enemies start the encounter")
	check(encounter.enemies[0].health==150,"Anchors have more health than level one")
	var caster: CharacterBody3D
	var guard: CharacterBody3D
	for enemy in encounter.enemies:
		enemy.set_physics_process(false)
		if enemy.enemy_title=="MORTARCAP": caster=enemy
		if enemy.enemy_title=="IRONROOT GUARD": guard=enemy
	check(guard.health==90 and guard.strike_damage==20,"Ironroot Guard is tougher and hits harder")
	for player in room.players: player.set_physics_process(false)
	room.party.set_physics_process(false)
	var hero=room.players[0];hero.position=Vector3(0,.1,14);hero.health=100;hero.invulnerability=0
	var bomb=Bomb.new();bomb.encounter=encounter;bomb.caster=caster;bomb.position=Vector3(0,0,14);encounter.add_child(bomb);bomb.set_physics_process(false)
	bomb._physics_process(.9)
	check(not bomb.active and hero.health==100,"Orange warning deals no damage before detonation")
	hero.position.x=4;bomb._physics_process(.31)
	check(bomb.active and hero.health==100,"Moving outside the marked circle avoids the bomb")
	hero.position.x=0;bomb._physics_process(.66)
	check(hero.health==94,"Lingering pool damages a player who walks back in")
	bomb._physics_process(3);await frames()
	check(not is_instance_valid(bomb),"Spore pool expires")
	hero.health=100;hero.invulnerability=0
	bomb=Bomb.new();bomb.encounter=encounter;bomb.caster=caster;bomb.position=Vector3(0,0,14);encounter.add_child(bomb);bomb.set_physics_process(false)
	bomb._physics_process(1.21)
	check(hero.health==78,"Standing in the warning takes the 22-damage impact")
	bomb.queue_free();await frames()
	bomb=Bomb.new();bomb.encounter=encounter;bomb.caster=caster;encounter.add_child(bomb);bomb.set_physics_process(false)
	caster.root_time=1;bomb._physics_process(.1)
	check(bomb.cancelled,"Snaring the caster cancels an unlaunched bomb")
	await frames();caster.root_time=0
	bomb=Bomb.new();bomb.encounter=encounter;bomb.caster=caster;encounter.add_child(bomb);bomb.set_physics_process(false)
	caster.stagger=.5;bomb._physics_process(.1)
	check(bomb.cancelled,"Knockback interrupts an unlaunched bomb")
	await frames();caster.stagger=0
	var before: int=encounter.count_enemies(false)
	encounter.enemies[0].take_damage(1000);await frames()
	check(encounter.reinforcements and encounter.count_enemies(false)==before+2,"First destroyed anchor triggers one reinforcement pair")
	encounter.advance(.1)
	check(encounter.count_enemies(false)==before+2,"Reinforcements trigger only once")
	for i in 30: encounter.spawn_rootling(Vector3(-20,0,14))
	check(encounter.count_enemies(false)==16,"Mobile enemy population is capped at sixteen")
	for enemy in encounter.enemies:
		if is_instance_valid(enemy): enemy.take_damage(10000)
	await frames()
	check(encounter.state==encounter.State.REWARD,"Clearing every enemy unlocks the Golden Pear")
	encounter.collect_pear()
	check(encounter.gate.collision_layer==0,"Collecting the pear opens the physical exit")
	var exit_route: PackedVector3Array=room.route_to(Vector3(0,0,-17),Vector3(0,0,-23))
	check(not exit_route.is_empty() and exit_route[-1].z==-23,"Opening the gate also opens companion navigation")
	for i in room.players.size(): room.players[i].position=Vector3(-1+i*.6,.1,-23)
	encounter.advance(.1)
	check(encounter.state==encounter.State.WON,"Both teams can complete level two")
	check(get_nodes_in_group("enemy_hazards").is_empty(),"Encounter completion leaves no hostile pools")
	room.queue_free();await frames(5)
	print("LEVEL TWO RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
