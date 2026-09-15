extends Node
## Two persistent pairs. Switching transfers input, never character state.
const LocalInput=preload("res://scripts/local_input.gd")
var room: Node3D
var teams: Array = []
var active := [0,0]
var switch_held := [false,false]
var paths: Dictionary = {}
var repath := 0.0

func setup(owner_room: Node3D) -> void:
	room=owner_room
	teams=[[room.players[0],room.players[1]],[room.players[2],room.players[3]]]
	for team in 2:
		for member in teams[team]:
			member.team_id=team
			member.device=-1-team
		update_control(team)

func current(team: int) -> CharacterBody3D:
	return teams[team][active[team]]

func update_control(team: int) -> void:
	for i in 2:
		var member=teams[team][i]
		member.controlled=i==active[team]
		member.companion_input=Vector2.ZERO
		member.companion_attack=false
		# A held power never casts again merely because control changes hands.
		member.power_held=LocalInput.power(member.device)
		for child in member.get_children():
			if child is Label3D:
				child.text="P%d%s" % [team+1,"" if member.controlled else " · FOLLOW"]
		member.get_node("PlayerRing").scale=Vector3.ONE*(1.3 if member.controlled else .8)

func switch_member(team: int) -> bool:
	if get_tree().paused or room.encounter.state in [room.encounter.State.WON,room.encounter.State.LOST]: return false
	var next:=1-int(active[team])
	if teams[team][next].downed: return false
	active[team]=next
	update_control(team)
	return true

func _physics_process(delta: float) -> void:
	if teams.is_empty(): return
	repath-=delta
	for team in 2:
		var held:=LocalInput.pressed(-1-team,"switch")
		if held and not switch_held[team]: switch_member(team)
		switch_held[team]=held
		if current(team).downed and not teams[team][1-active[team]].downed:
			switch_member(team)
		var follower=teams[team][1-active[team]]
		follower.companion_input=Vector2.ZERO
		follower.companion_attack=false
		if follower.downed or room.encounter.state not in [room.encounter.State.COMBAT,room.encounter.State.REWARD,room.encounter.State.EXIT]: continue
		var leader=current(team)
		if leader.downed: continue
		var away:=Vector3.ZERO
		var hazard_near:=false
		for hazard in get_tree().get_nodes_in_group("enemy_hazards"):
			var offset: Vector3=follower.global_position-hazard.global_position;offset.y=0
			if offset.length()<hazard.radius+.8:
				hazard_near=true
				if offset.length()<.05: offset=Vector3.RIGHT
				away+=offset.normalized()*(hazard.radius+1-offset.length())*3
		for enemy in room.encounter.enemies:
			if not is_instance_valid(enemy) or enemy.dead: continue
			var offset: Vector3=follower.position-enemy.position;offset.y=0
			if offset.length()<2.0:
				away+=offset.normalized()*(2.0-offset.length())
		var destination: Vector3=leader.position
		var distance: float=follower.position.distance_to(leader.position)
		var move_needed:=distance>2.4
		if room.encounter.state==room.encounter.State.EXIT and leader.position.z<-19:
			destination=Vector3(clampf(leader.position.x,-1.5,1.5),0,-23.3)
			move_needed=follower.position.z>-22.4
		if away.length()>.15 and (distance<5.0 or hazard_near):
			destination=follower.position+away.normalized()*2.5
			move_needed=true
		if move_needed:
			if repath<=0 or not paths.has(follower): paths[follower]=room.route_to(follower.position,destination)
			var route: PackedVector3Array=paths[follower]
			while not route.is_empty() and Vector2(route[0].x-follower.position.x,route[0].z-follower.position.z).length()<.45:
				route.remove_at(0)
			paths[follower]=route
			if not route.is_empty():
				var direction: Vector3=(route[0]-follower.position);direction.y=0
				follower.companion_input=Vector2(direction.x-direction.z,direction.x+direction.z).normalized()
		else: paths.erase(follower)
		if follower.combat_enabled and distance<6.0:
			var target=room.encounter.nearest_enemy(follower.position,[3.6,9.0,6.0,7.0][follower.class_id])
			follower.companion_attack=target!=null
	if repath<=0: repath=.25
