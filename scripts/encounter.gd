extends Node3D

const Enemy = preload("res://scripts/enemy.gd")
const LocalInput = preload("res://scripts/local_input.gd")
enum State { LOBBY, COMBAT, REWARD, EXIT, WON, LOST }
var state: State = State.LOBBY
var room: Node3D
var enemies: Array = []
var pear: MeshInstance3D
var gate: StaticBody3D
var reward_position := Vector3(0, 0, -17)
const EXIT_Z := -22.0
const EXIT_HALF_WIDTH := 2.5

func _ready() -> void:
	room = get_parent()
	gate = room.box(Vector3(5, 2.0, 0.5), Vector3(0, 1.0, -20), Color("694c70"), true)
	gate.name = "PlaceholderRootGate"
	room.box(Vector3(21.5, 2, 0.5), Vector3(-13.25, 1, -20), Color("425347"), true)
	room.box(Vector3(21.5, 2, 0.5), Vector3(13.25, 1, -20), Color("425347"), true)
	var exit_label := Label3D.new()
	exit_label.text = "ROOT GATE / EXIT"
	exit_label.position = Vector3(0, 2.8, -20)
	exit_label.pixel_size = 0.012
	exit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(exit_label)

func begin() -> void:
	if state != State.LOBBY:
		return
	state = State.COMBAT
	for player in room.players:
		player.combat_enabled = true
	for point in [Vector3(-12, 0, -11), Vector3(12, 0, -11)]:
		var heart = Enemy.new()
		heart.is_heart = true
		heart.health = 100.0
		heart.max_health = 100.0
		heart.encounter = self
		heart.position = point
		add_child(heart)
		enemies.append(heart)
		spawn_rootling(point + Vector3(0, 0, 2))

func spawn_rootling(point: Vector3) -> void:
	if state != State.COMBAT or count_enemies(false) >= 10:
		return
	var rootling = Enemy.new()
	rootling.encounter = self
	rootling.position = point
	add_child(rootling)
	enemies.append(rootling)

func count_enemies(hearts: bool) -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.is_heart == hearts:
			count += 1
	return count

func nearest_survivor(point: Vector3) -> CharacterBody3D:
	var nearest: CharacterBody3D = null
	var distance := INF
	for player in room.players:
		if not player.downed and point.distance_squared_to(player.position) < distance:
			nearest = player
			distance = point.distance_squared_to(player.position)
	return nearest

func attack(player: CharacterBody3D) -> void:
	if state != State.COMBAT or player.downed:
		return
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			if player.position.distance_to(enemy.position) <= player.POWER_RADIUS:
				var query := PhysicsRayQueryParameters3D.create(player.position + Vector3.UP * 0.7, enemy.position + Vector3.UP * 0.7, 1)
				if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
					enemy.take_damage(20.0, player.position)

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if state == State.LOBBY or state == State.WON or state == State.LOST:
		return
	if nearest_survivor(Vector3.ZERO) == null:
		finish(State.LOST)
		return
	update_revives(delta)
	if state == State.COMBAT:
		enemies = enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.dead)
		if count_enemies(true) == 0 and count_enemies(false) == 0:
			state = State.REWARD
			pear = MeshInstance3D.new()
			pear.name = "PlaceholderGoldenPear"
			var mesh := SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.2
			pear.mesh = mesh
			pear.position = reward_position + Vector3(0, 0.8, 0)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("ffd85c")
			material.emission_enabled = true
			material.emission = Color("8f631a")
			pear.material_override = material
			add_child(pear)
			var label := Label3D.new()
			label.text = "GOLDEN PEAR"
			label.position.y = 1.2
			label.pixel_size = 0.012
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			pear.add_child(label)
	elif state == State.REWARD:
		for player in room.players:
			if not player.downed and player.position.distance_to(reward_position) < 1.3:
				collect_pear()
				break
	elif state == State.EXIT:
		var everyone_out := true
		for player in room.players:
			if not player.downed and (player.position.z > EXIT_Z or absf(player.position.x) > EXIT_HALF_WIDTH):
				everyone_out = false
		if everyone_out:
			finish(State.WON)

func collect_pear() -> void:
	if state != State.REWARD:
		return
	state = State.EXIT
	pear.queue_free()
	gate.hide()
	gate.collision_layer = 0
	# Companions must see the same open gate as physics does.
	for x in range(-2,3):
		for z in range(-21,-18): room.navigation.set_point_solid(Vector2i(x,z),false)
	gate.collision_mask = 0

func update_revives(delta: float) -> void:
	for fallen in room.players:
		if not fallen.downed:
			continue
		var helping := false
		for helper in room.players:
			if helper != fallen and not helper.downed and helper.invulnerability <= 0.0:
				if helper.controlled and helper.position.distance_to(fallen.position) <= 2.0 and LocalInput.interact(helper.device):
					helping = true
		fallen.revive_progress = fallen.revive_progress + delta if helping else 0.0
		if fallen.revive_progress >= 2.0:
			fallen.revive()

func finish(result: State) -> void:
	state = result
	for player in room.players:
		player.combat_enabled = false
		player.velocity = Vector3.ZERO
		player.set_physics_process(false)

func objective() -> String:
	match state:
		State.LOBBY:
			return "CORRUPTED CLEARING\nJoin your party, then press Enter / controller Y to begin."
		State.COMBAT:
			return "Destroy the corruption  •  Hearts: %d / 2  •  Rootlings: %d" % [count_enemies(true), count_enemies(false)]
		State.REWARD:
			return "Clearing restored. Collect the GOLDEN PEAR near the gate."
		State.EXIT:
			return "Gate open. Bring every surviving gnome through the exit."
		State.WON:
			return "CLEARING COMPLETE  •  Press R / controller Back to play again."
		State.LOST:
			return "PARTY DOWN  •  Press R / controller Back to retry."
	return ""
