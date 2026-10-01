extends "res://scripts/realm_encounter.gd"
var reinforcements:=false

func begin() -> void:
	if state!=State.LOBBY: return
	state=State.COMBAT
	for player in room.players: player.combat_enabled=true
	for point in [Vector3(-16,0,-9),Vector3(15,0,-5),Vector3(0,0,-14)]:
		var heart=Enemy.new();heart.is_heart=true;heart.enemy_title="CISTERN ANCHOR"
		heart.health=150;heart.max_health=150;heart.spawn_delay=7;heart.cooldown=7;heart.encounter=self;heart.position=point
		add_child(heart);enemies.append(heart)
	for point in [Vector3(-12,0,7),Vector3(12,0,9),Vector3(-15,0,-5),Vector3(13,0,-1)]: spawn_rootling(point)
	spawn_guard(Vector3(-13,0,-8));spawn_guard(Vector3(3,0,-13))
	spawn_mortar(Vector3(-17,0,-12));spawn_mortar(Vector3(16,0,-9))

func spawn_rootling(point: Vector3) -> void:
	if state!=State.COMBAT or count_enemies(false)>=16: return
	var enemy=Enemy.new();enemy.encounter=self;enemy.position=point
	enemy.health=42;enemy.max_health=42;enemy.strike_damage=14
	add_child(enemy);enemies.append(enemy)

func spawn_guard(point: Vector3) -> void:
	if count_enemies(false)>=16: return
	var enemy=Enemy.new();enemy.encounter=self;enemy.position=point
	enemy.health=90;enemy.max_health=90;enemy.move_speed=1.8;enemy.strike_damage=20;enemy.strike_windup=.8
	enemy.enemy_title="IRONROOT GUARD";add_child(enemy);enemies.append(enemy)
	enemy.label.position.y=2.7

func spawn_mortar(point: Vector3) -> void:
	if count_enemies(false)>=16: return
	var enemy=load("res://scripts/mortarcap.gd").new();enemy.encounter=self;enemy.position=point
	add_child(enemy);enemies.append(enemy)

func advance(delta: float) -> void:
	if state==State.COMBAT and not reinforcements and count_enemies(true)<3:
		reinforcements=true
		spawn_guard(Vector3(-4,0,-17));spawn_mortar(Vector3(7,0,-16))
	super.advance(delta)

func finish(result: State) -> void:
	super.finish(result)
	for hazard in get_tree().get_nodes_in_group("enemy_hazards"):
		if is_ancestor_of(hazard): hazard.queue_free()
