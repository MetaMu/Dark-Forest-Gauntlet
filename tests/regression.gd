extends SceneTree

const Room = preload("res://scripts/clearing.gd")
const LocalInput = preload("res://scripts/local_input.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func new_room():
	var room = Room.new()
	root.add_child(room)
	return room

func run() -> void:
	var room = new_room()
	await physics_frame
	check(room.players.size() == 1, "keyboard player exists")
	room.join_player(100)
	room.join_player(100)
	check(room.players.size() == 2, "same device cannot claim duplicate slots")
	room.join_player(101)
	room.join_player(102)
	room.join_player(103)
	check(room.players.size() == 4, "party capped at four")
	check(LocalInput.movement(100) == Vector2.ZERO, "missing controller stops movement")
	var player = room.players[0]
	key(KEY_D, true)
	var origin: Vector3 = player.position
	for i in 30:
		await physics_frame
	check(player.position.x > origin.x and player.position.z < origin.z, "keyboard movement follows screen right")
	key(KEY_W, true)
	check(is_equal_approx(LocalInput.movement(-1).length(), 1.0), "diagonal input is normalized")
	key(KEY_D, false)
	key(KEY_W, false)
	player.position = Vector3(13.2, 0.1, 0)
	key(KEY_D, true)
	key(KEY_S, true)
	for i in 45:
		await physics_frame
	key(KEY_D, false)
	key(KEY_S, false)
	check(player.position.x < 13.6, "arena wall blocks player")
	for i in room.players.size():
		room.players[i].position = Vector3(-12 if i % 2 == 0 else 12, 0, -7 if i < 2 else 10)
	room.update_camera(10.0)
	for pawn in room.players:
		var screen: Vector2 = room.camera.unproject_position(pawn.position + Vector3.UP)
		check(root.get_visible_rect().has_point(screen), "camera frames separated player")
	room.free()
	await process_frame

	room = new_room()
	player = room.players[0]
	room.encounter.begin()
	check(room.encounter.count_enemies(true) == 2 and room.encounter.count_enemies(false) == 2, "encounter starts with two Hearts and two Rootlings")
	room.join_player(100)
	check(room.players.size() == 1, "joining is locked during encounter")
	for i in 20:
		room.encounter.spawn_rootling(Vector3(8, 0, 3))
	check(room.encounter.count_enemies(false) == 10, "spawn cap prevents unbounded swarm")
	var heart = room.encounter.enemies[0]
	player.position = heart.position + Vector3(0, 0, 1.5)
	check(player.try_attack(), "living player can attack")
	check(heart.health == 80.0, "attack damages nearby Heart")
	check(not player.try_attack() and heart.health == 80.0, "cooldown prevents repeated damage")
	player.take_damage(12.0)
	player.take_damage(12.0)
	check(player.health == 88.0, "damage immunity prevents simultaneous stacked hits")
	for enemy in room.encounter.enemies:
		if enemy.is_heart:
			enemy.take_damage(1000.0)
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.COMBAT, "remaining Rootlings block reward after Hearts die")
	for enemy in room.encounter.enemies:
		enemy.take_damage(1000.0)
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.REWARD, "complete clear produces Golden Pear")
	check(room.encounter.gate.collision_layer != 0, "gate stays solid before pickup")
	player.position = room.encounter.reward_position
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.EXIT and room.encounter.gate.collision_layer == 0, "pear collection opens physical gate")
	player.position = Vector3(0, 0, room.encounter.EXIT_Z - 0.5)
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.WON, "survivor reaching exit wins")
	check(not player.combat_enabled and not player.is_physics_processing(), "win freezes gameplay")
	room.free()
	await process_frame

	room = new_room()
	room.join_player(100)
	player = room.players[0]
	var ally = room.players[1]
	room.encounter.begin()
	ally.take_damage(1000.0)
	ally.position = player.position + Vector3(0.5, 0, 0)
	check(ally.downed and not ally.try_attack(), "downed players cannot attack")
	key(KEY_E, true)
	room.encounter.update_revives(1.0)
	check(ally.downed, "revive requires sustained hold")
	key(KEY_E, false)
	room.encounter.update_revives(0.1)
	check(ally.revive_progress == 0.0, "releasing interact resets revive")
	key(KEY_E, true)
	room.encounter.update_revives(2.1)
	key(KEY_E, false)
	check(not ally.downed and ally.health == 40.0, "nearby held interact revives ally")
	player.take_damage(1000.0)
	ally.invulnerability = 0.0
	ally.take_damage(1000.0)
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.LOST, "all downed ends run in failure")
	room.free()
	await process_frame

	room = new_room()
	room.join_player(100)
	room.encounter.begin()
	player = room.players[0]
	ally = room.players[1]
	var spawner = room.encounter.enemies[0]
	spawner.cooldown = 0.0
	spawner._physics_process(0.1)
	check(room.encounter.count_enemies(false) == 3, "living Heart emits timed spawn")
	var rootling = room.encounter.enemies[1]
	rootling.position = player.position + Vector3(0.0, 0.0, 1.0)
	rootling.cooldown = 0.0
	rootling._physics_process(0.1)
	check(player.health == 100.0 and rootling.windup > 0.0, "enemy warns before strike")
	rootling._physics_process(0.6)
	check(player.health == 88.0, "enemy windup resolves into damage")
	for enemy in room.encounter.enemies:
		enemy.take_damage(1000.0)
	room.encounter.advance(0.0)
	player.position = room.encounter.reward_position
	room.encounter.advance(0.0)
	player.position = Vector3(0, 0, room.encounter.EXIT_Z - 0.5)
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.EXIT, "exit waits for every survivor")
	ally.position = Vector3(0.5, 0, room.encounter.EXIT_Z - 0.5)
	room.encounter.advance(0.0)
	check(room.encounter.state == room.encounter.State.WON, "full surviving party completes encounter")
	room.free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
