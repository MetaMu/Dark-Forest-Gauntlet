extends SceneTree
const Controls=preload("res://scripts/local_input.gd")
func _initialize() -> void: call_deferred("run")
func held(team: int, action: String, value: bool) -> void:
	if value: Input.action_press(Controls.action_name(-1-team,action))
	else: Input.action_release(Controls.action_name(-1-team,action))
func run() -> void:
	var room=load("res://scenes/bellcap_cistern.tscn").instantiate();root.add_child(room)
	room.enable_keyboard_party();room.encounter.begin()
	for frame in 14400:
		if room.encounter.state in [room.encounter.State.WON,room.encounter.State.LOST]: break
		for team in 2:
			var actor=room.party.current(team)
			var enemy=room.encounter.nearest_enemy(actor.position,70)
			# nearest_enemy uses line of sight; navigate toward a hidden enemy when needed.
			if enemy==null:
				for other in room.encounter.enemies:
					if is_instance_valid(other) and not other.dead:
						if enemy==null or actor.position.distance_to(other.position)<actor.position.distance_to(enemy.position): enemy=other
			var destination: Vector3=actor.position
			var moving:=false
			var danger:=false
			if enemy!=null:
				destination=enemy.position
				moving=actor.position.distance_to(destination)>[2.8,6.0,3.6,5.0][actor.class_id] or not room.encounter.visible_to(actor.position,destination)
			elif room.encounter.state==room.encounter.State.REWARD: destination=Vector3(0,0,-17);moving=true
			elif room.encounter.state==room.encounter.State.EXIT: destination=Vector3(-.7+team*1.4,0,-23.4);moving=actor.position.z>-23
			for bomb in get_nodes_in_group("enemy_hazards"):
				var away: Vector3=actor.position-bomb.position;away.y=0
				if away.length()<bomb.radius+.7:
					if away.length()<.15: away=Vector3(1 if team==0 else -1,0,1)
					destination=actor.position+away.normalized()*4;moving=true;danger=true
			var direction:=Vector3.ZERO
			if moving:
				var route: PackedVector3Array=room.route_to(actor.position,destination)
				while not route.is_empty() and Vector2(route[0].x-actor.position.x,route[0].z-actor.position.z).length()<.4: route.remove_at(0)
				if not route.is_empty(): direction=route[0]-actor.position
			var move:=Vector2(direction.x-direction.z,direction.x+direction.z).normalized()
			held(team,"left",move.x<-.25);held(team,"right",move.x>.25);held(team,"up",move.y<-.25);held(team,"down",move.y>.25)
			held(team,"attack",enemy!=null)
			held(team,"power",enemy!=null and actor.position.distance_to(enemy.position)<5 and frame%60==0)
			var partner=room.party.teams[team][1-room.party.active[team]]
			held(team,"switch",not danger and not partner.downed and actor.power_cooldown>3 and partner.power_cooldown<=0 and frame%90==0)
			held(team,"revive",true)
		await physics_frame
		if frame%1800==0: print("PLAYTHROUGH ",frame/60,"s: enemies=",room.encounter.count_enemies(false)," anchors=",room.encounter.count_enemies(true))
	print("LEVEL TWO PLAYTHROUGH STATE: ",room.encounter.state," (WON=",room.encounter.State.WON,")")
	for actor in room.players: print("FINAL HERO ",actor.class_id," HP=",actor.health," DOWN=",actor.downed," POS=",actor.position)
	var won: bool=room.encounter.state==room.encounter.State.WON
	for team in 2:
		for action in Controls.ACTIONS: held(team,action,false)
	room.queue_free();await process_frame;quit(0 if won else 1)
