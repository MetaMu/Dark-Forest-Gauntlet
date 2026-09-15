extends "res://scripts/encounter.gd"
const FX = preload("res://scripts/combat_fx.gd")
const Projectile = preload("res://scripts/realm_projectile.gd")
const VFX = preload("res://scripts/realm_vfx.gd")
var clouds: Array[Dictionary] = []
var elapsed := 0.0

func collect_pear() -> void:
	if state!=State.REWARD: return
	if room.level_id==1:
		# Defer scene replacement until this physics callback has finished.
		room.transitioning=true
		finish(State.WON)
		if is_instance_valid(pear): pear.queue_free()
		room.travel_to_level.call_deferred(2,true)
	else:
		super.collect_pear()

func realm_power(player: CharacterBody3D) -> void:
	if state!=State.COMBAT or player.downed: return
	var color: Color=room.COLORS[player.class_id]
	room.prepare_attack(player)
	room.play_sound("power",-14.0)
	VFX.cast_flare(player,color)
	match player.class_id:
		0:
			player.dash_direction=Vector3(player.last_input.x+player.last_input.y,0,player.last_input.y-player.last_input.x).normalized()
			player.dash_time=0.18
			player.invulnerability=maxf(player.invulnerability,0.3)
			VFX.dash(self,player)
		1:
			var direction:=Vector3(player.last_input.x+player.last_input.y,0,player.last_input.y-player.last_input.x).normalized()
			for angle in [-0.17,0.0,0.17]:
				var bolt=Projectile.new()
				bolt.direction=direction.rotated(Vector3.UP,angle)
				bolt.source=player.position
				bolt.damage=25.0
				bolt.remaining_hits=3
				bolt.speed=20.0
				bolt.lifetime=0.7
				bolt.color=color
				bolt.encounter=self
				bolt.position=player.position+Vector3.UP*0.7
				add_child(bolt)
		2:
			VFX.snare_cast(self,player.position)
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.dead and player.position.distance_to(enemy.position)<=5.0 and visible_to(player.position,enemy.position):
					enemy.root_time=2.5
					enemy.slow_time=4.0
					enemy.take_damage(15.0)
					VFX.root_target(enemy)
					FX.number(self,enemy.position,"SNARED",color)
		3:
			VFX.sanctuary(self,player.position)
			for ally in room.players:
				if ally.position.distance_to(player.position)<=5.0 and visible_to(player.position,ally.position):
					if ally.downed:
						ally.revive()
						FX.number(self,ally.position,"REVIVED",color)
					else:
						var amount:=minf(25.0,100.0-ally.health)
						ally.health+=amount
						FX.number(self,ally.position,"+%d"%int(amount),color)
					ally.invulnerability=maxf(ally.invulnerability,1.0)
					VFX.heal_ally(self,player.position,ally)

func ember_landing(player: CharacterBody3D) -> void:
	if state!=State.COMBAT or player.downed: return
	var color:=Color("ff963c")
	VFX.ember_impact(self,player.position)
	room.play_sound("attack",-12.0)
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and player.position.distance_to(enemy.position)<=3.0 and visible_to(player.position,enemy.position):
			enemy.take_damage(35.0,player.position)
			FX.number(self,enemy.position,"35",color)

func visible_to(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.7, to + Vector3.UP * 0.7, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func nearest_enemy(point: Vector3, radius: float):
	var nearest = null
	var best := radius
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			var distance: float = point.distance_to(enemy.position)
			if distance < best and visible_to(point, enemy.position):
				best = distance
				nearest = enemy
	return nearest

func attack(player: CharacterBody3D) -> void:
	if state != State.COMBAT or player.downed:
		return
	var color: Color = room.COLORS[player.class_id]
	room.play_sound("attack", -16.0)
	match player.class_id:
		0:
			VFX.ember_sweep(self, player.global_position)
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.dead and player.position.distance_to(enemy.position) <= 4.0 and visible_to(player.position, enemy.position):
					enemy.take_damage(20.0,player.position)
					FX.number(self, enemy.position,"20",color)
		1, 3:
			var target = nearest_enemy(player.position, 11.0 if player.class_id == 1 else 8.0)
			var aim := Vector3(player.last_input.x + player.last_input.y,0,player.last_input.y-player.last_input.x).normalized()
			if target != null:
				aim = (target.position-player.position).normalized()
				aim.y = 0
			var bolt = Projectile.new()
			bolt.direction = aim.normalized()
			bolt.source = player.position
			bolt.damage = 22.0 if player.class_id == 1 else 16.0
			bolt.color = color
			bolt.nature = player.class_id==1
			bolt.encounter = self
			bolt.position = player.position + Vector3.UP * 0.7
			add_child(bolt)
			if player.class_id == 3:
				for ally in room.players:
					if not ally.downed and ally.position.distance_to(player.position) <= 4.0 and visible_to(player.position,ally.position):
						var amount := minf(4.0,100.0-ally.health)
						ally.health += amount
						if amount > 0.0:
							VFX.heal_ally(self,player.position,ally,false)
							FX.number(self,ally.position,"+%d" % int(amount),Color("c2ef9b"))
		2:
			var target = nearest_enemy(player.position,7.0)
			var point: Vector3 = target.position if target != null else player.position
			if clouds.size() >= 3:
				var oldest: Dictionary = clouds.pop_front()
				if is_instance_valid(oldest.visual):
					oldest.visual.queue_free()
			var visual = VFX.cloud(self,point)
			clouds.append({"point":point,"life":3.0,"tick":0.0,"visual":visual,"source":player.position})

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state != State.COMBAT:
		return
	elapsed += delta
	for cloud in clouds:
		cloud.life -= delta
		cloud.tick -= delta
		if cloud.tick <= 0.0:
			cloud.tick = 0.6
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.dead and enemy.position.distance_to(cloud.point) < 2.8 and visible_to(cloud.point,enemy.position):
					enemy.slow_time = 1.0
					enemy.take_damage(6.0)
					FX.number(self,enemy.position,"6",Color("d8b6fa"))
	clouds = clouds.filter(func(cloud): return cloud.life > 0.0)
