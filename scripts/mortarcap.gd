extends "res://scripts/enemy.gd"
var cast_target:=Vector3.ZERO
var cap: Node3D

func _ready() -> void:
	enemy_title="MORTARCAP";health=60;max_health=60;cooldown=2.0
	super._ready()
	cap=Node3D.new();add_child(cap)
	label.position.y=2.8;label.modulate=Color("d5ed85")

func _physics_process(delta: float) -> void:
	if dead:
		super._physics_process(delta)
		return
	if encounter.state!=encounter.State.COMBAT: return
	cooldown-=delta;root_time=maxf(0,root_time-delta);slow_time=maxf(0,slow_time-delta);hit_flash=maxf(0,hit_flash-delta)
	cap.scale=Vector3(1,1+.06*sin(Time.get_ticks_msec()*.004),1)
	if root_time>0 or stagger>0:
		stagger=maxf(0,stagger-delta);windup=-1;velocity=Vector3.ZERO;return
	if windup>=0:
		windup-=delta;velocity=Vector3.ZERO;cap.scale=Vector3(1.12,.85,1.12)
		return
	target=encounter.nearest_survivor(position)
	if target==null: return
	var offset:=target.position-position;offset.y=0
	if offset.length()<=12 and encounter.visible_to(position,target.position) and cooldown<=0:
		var bomb=load("res://scripts/spore_bomb.gd").new()
		bomb.encounter=encounter;bomb.caster=self;bomb.position=target.position;bomb.position.y=.02
		encounter.add_child(bomb);windup=1.2;cooldown=4.8
		if has_combat_clips(): creature_visual.begin_attack(1.2)
		return
	var destination: Vector3=target.position
	if offset.length()<4.0: destination=position-offset.normalized()*3
	elif offset.length()<8 and encounter.visible_to(position,target.position): velocity=Vector3.ZERO;return
	repath-=delta
	if repath<=0: repath=.4;route=encounter.room.route_to(position,destination)
	while not route.is_empty() and position.distance_to(route[0])<.65: route.remove_at(0)
	if not route.is_empty():
		velocity=(route[0]-position).normalized()*(.8 if slow_time>0 else 1.7);velocity.y=-2;move_and_slide()
