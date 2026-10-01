extends CharacterBody3D
## Shared damage interface for the stationary Heart and mobile Rootling proxies.
var is_heart: bool = false
var health: float = 30.0
var max_health: float = 30.0
var dead: bool = false
var encounter: Node
var label: Label3D
var material: StandardMaterial3D
var cooldown: float = 1.0
var windup: float = -1.0
var target: CharacterBody3D
var knockback := Vector3.ZERO
var stagger: float = 0.0
var hit_flash: float = 0.0
var route: PackedVector3Array = []
var repath: float = 0.0
var slow_time: float = 0.0
var health_bar: Sprite3D
var root_time := 0.0
var enemy_title := ""
var move_speed := 2.3
var strike_damage := 12.0
var strike_windup := .55
var spawn_delay := 5.0
var creature_visual: Node3D
var attack_recovery := 0.0
var death_time_remaining := -1.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 7
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.85 if is_heart else 0.35
	collision.shape = shape
	collision.position.y = shape.radius
	add_child(collision)
	var mesh := MeshInstance3D.new()
	mesh.name = "PlaceholderRootHeart" if is_heart else "PlaceholderRootling"
	var sphere := SphereMesh.new()
	sphere.radius = shape.radius
	sphere.height = shape.radius * 2.0
	mesh.mesh = sphere
	mesh.position.y = shape.radius
	material = StandardMaterial3D.new()
	material.albedo_color = Color("a8466a") if is_heart else Color("b9bc73")
	mesh.material_override = material
	add_child(mesh)
	label = Label3D.new()
	label.position.y = shape.radius * 2.0 + 0.6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 36
	label.pixel_size = 0.012
	add_child(label)
	update_label()
	if encounter != null and encounter.room.has_method("play_sound"):
		mesh.hide()
		var creature = load("res://scripts/root_creature.gd").new()
		add_child(creature)
		creature_visual = creature
		label.position.y = 3.2 if is_heart else 1.8
		label.font_size = 24
		label.pixel_size = 0.01
		update_label()

func _physics_process(delta: float) -> void:
	if dead:
		if death_time_remaining >= 0.0:
			death_time_remaining -= delta
			if death_time_remaining < 0.0:
				queue_free()
		return
	if encounter == null or encounter.state != encounter.State.COMBAT:
		return
	cooldown -= delta
	slow_time = maxf(0.0,slow_time-delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	root_time=maxf(0.0,root_time-delta)
	if hit_flash <= 0.0 and windup < 0.0:
		material.emission_enabled = false
	if stagger > 0.0:
		stagger = maxf(0.0, stagger - delta)
		velocity = knockback
		velocity.y = -2.0
		move_and_slide()
		knockback = knockback.move_toward(Vector3.ZERO, 18.0 * delta)
		return
	if is_heart:
		if cooldown <= 0.0:
			cooldown = spawn_delay
			if has_combat_clips(): creature_visual.begin_attack(.8)
			encounter.spawn_rootling(position + Vector3(1.4, 0, 0))
		return
	if root_time>0.0:
		velocity=Vector3.ZERO
		windup=-1.0
		return
	if windup >= 0.0:
		velocity = Vector3.ZERO
		windup -= delta
		if windup <= 0.0:
			if is_instance_valid(target) and not target.downed and position.distance_to(target.position) < 1.5:
				target.take_damage(strike_damage)
			windup = -1.0
			if has_combat_clips():
				attack_recovery = 0.25
			cooldown = 1.0
			material.emission_enabled = false
		return
	if attack_recovery > 0.0:
		attack_recovery = maxf(0.0, attack_recovery - delta)
		velocity = Vector3.ZERO
		return
	target = encounter.nearest_survivor(position)
	if target == null:
		return
	var offset := target.position - position
	offset.y = 0.0
	if offset.length() <= 1.15:
		velocity = Vector3.ZERO
		if cooldown <= 0.0:
			windup = strike_windup
			velocity = Vector3.ZERO
			if has_combat_clips():
				creature_visual.begin_attack(strike_windup)
			material.emission_enabled = true
			material.emission = Color("f44d35")
	else:
		repath -= delta
		if repath <= 0.0:
			repath = 0.35
			route = encounter.room.route_to(position, target.position)
		while not route.is_empty() and position.distance_to(route[0]) < 0.7:
			route.remove_at(0)
		var direction := offset.normalized()
		if not route.is_empty():
			direction = (route[0] - position).normalized()
		velocity = direction * (move_speed*.435 if slow_time > 0.0 else move_speed)
		velocity.y = -2.0
		move_and_slide()

func take_damage(amount: float, source: Vector3 = Vector3.INF) -> void:
	if dead or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	material.emission_enabled = true
	material.emission = Color("fff0c0")
	hit_flash = 0.22
	if encounter!=null and encounter.room.has_method("play_sound"):
		encounter.room.play_sound("hit",-23.0)
		load("res://scripts/combat_fx.gd").burst(encounter,position+Vector3.UP*0.8,Color("ffe1a0"),0.6)
	if not is_heart and source != Vector3.INF:
		var away := position - source
		away.y = 0.0
		if away.length_squared() < 0.01:
			away = Vector3.FORWARD
		knockback = away.normalized() * 11.0
		stagger = 0.5
		windup = -1.0
		attack_recovery = 0.0
		cooldown = 0.9
		repath = 0.0
	update_label()
	if health <= 0.0:
		dead = true
		if has_combat_clips():
			death_time_remaining = 1.5
			creature_visual.begin_death()
			label.hide()
			collision_layer = 0
			collision_mask = 0
		else:
			queue_free()
	elif has_combat_clips():
		creature_visual.begin_hit()

func has_combat_clips() -> bool:
	return is_instance_valid(creature_visual) and creature_visual.has_method("supports_combat_clips") and creature_visual.supports_combat_clips()

func update_label() -> void:
	if label != null:
		if encounter != null and encounter.room.has_method("play_sound"):
			label.text = ("ROOT HEART\n" if is_heart else "") + "▰".repeat(maxi(1,ceili(health/max_health*5)))
			if not enemy_title.is_empty(): label.text=enemy_title+"\n"+"▰".repeat(maxi(1,ceili(health/max_health*5)))
			label.modulate=Color("e38aad") if is_heart else Color("d3ce9f")
		else:
			label.text = "%s  %d" % ["ROOT HEART" if is_heart else "Rootling", int(health)]
