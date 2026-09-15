extends Node3D

const Player = preload("res://scripts/player.gd")
const Encounter = preload("res://scripts/encounter.gd")
const REALMS := ["Ember Hollow", "Ironbark Frontier", "Spore Grove", "Light Realm"]
const COLORS := [Color("e67948"), Color("73b68b"), Color("b48cdd"), Color("f0d887")]
var players: Array[CharacterBody3D] = []
var camera: Camera3D
var roster: Label
var objective_label: Label
var focus := Vector3.ZERO
var encounter: Node3D
var navigation := AStarGrid2D.new()
var obstacles: Array[Rect2] = []

func _ready() -> void:
	Player.LocalInput.configure()
	build_clearing()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.3
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a7b8ac")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.0
	add_child(camera)
	camera.current = true
	var hud := CanvasLayer.new()
	add_child(hud)
	var top := ColorRect.new()
	top.color = Color(0.02, 0.035, 0.03, 0.9)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 112
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	var heading := Label.new()
	heading.text = "DARK FOREST GAUNTLET"
	heading.position = Vector2(24, 12)
	heading.add_theme_font_size_override("font_size", 24)
	hud.add_child(heading)
	var controls := Label.new()
	controls.text = "WASD / stick: move    Space / X: attack    Hold E / A: revive    Start: join    Enter / Y: begin"
	controls.position = Vector2(24, 45)
	controls.add_theme_font_size_override("font_size", 16)
	hud.add_child(controls)
	objective_label = Label.new()
	objective_label.position = Vector2(24, 76)
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.modulate = Color("f0d887")
	hud.add_child(objective_label)
	var bottom := ColorRect.new()
	bottom.color = Color(0.02, 0.035, 0.03, 0.9)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -116
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bottom)
	roster = Label.new()
	hud.add_child(roster)
	roster.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	roster.offset_left = 24
	roster.offset_top = -106
	roster.add_theme_font_size_override("font_size", 16)
	join_player(-1)
	encounter = create_encounter()
	encounter.name = "Encounter"
	add_child(encounter)
	build_navigation()
	update_camera(1.0)

func create_encounter() -> Node3D:
	return Encounter.new()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		join_player(event.device)
	if encounter == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ENTER:
			encounter.begin()
		elif event.physical_keycode == KEY_R:
			restart()
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_Y:
			encounter.begin()
		elif event.button_index == JOY_BUTTON_BACK:
			restart()

func restart() -> void:
	if encounter.state in [Encounter.State.WON, Encounter.State.LOST]:
		get_tree().reload_current_scene()

func join_player(device: int) -> void:
	if encounter != null and encounter.state != Encounter.State.LOBBY:
		return
	for player in players:
		if player.device == device:
			return
	if players.size() >= 4:
		return
	var slot := players.size()
	var player := Player.new()
	player.device = device
	player.collision_layer = 4
	player.collision_mask = 3
	player.attack_requested.connect(on_attack)
	player.name = "Player%d" % (slot + 1)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.5
	collision.shape = capsule
	collision.position.y = 0.75
	player.add_child(collision)
	var visual := Node3D.new()
	visual.name = "PlaceholderVisual"
	player.add_child(visual)
	player.visual = visual
	var mesh := MeshInstance3D.new()
	var placeholder := CapsuleMesh.new()
	placeholder.radius = 0.4
	placeholder.height = 1.5
	mesh.mesh = placeholder
	mesh.position.y = 0.75
	var material := StandardMaterial3D.new()
	material.albedo_color = COLORS[slot]
	mesh.material_override = material
	visual.add_child(mesh)
	var pulse := MeshInstance3D.new()
	pulse.name = "PlaceholderAttackRadius"
	var ring := TorusMesh.new()
	ring.inner_radius = Player.POWER_RADIUS - 0.18
	ring.outer_radius = Player.POWER_RADIUS
	pulse.mesh = ring
	pulse.position.y = 0.15
	var power_material := StandardMaterial3D.new()
	power_material.albedo_color = COLORS[slot]
	power_material.emission_enabled = true
	power_material.emission = COLORS[slot]
	pulse.material_override = power_material
	pulse.visible = false
	player.add_child(pulse)
	player.attack_visual = pulse
	var marker := Label3D.new()
	marker.text = "P%d" % (slot + 1)
	marker.position.y = 2.0
	marker.font_size = 48
	marker.pixel_size = 0.012
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player.add_child(marker)
	add_child(player)
	player.position = Vector3((slot % 2) * 2 - 1, 0.1, floori(slot / 2.0) * 2 + 15)
	players.append(player)

func _process(delta: float) -> void:
	update_camera(delta)
	var text := ""
	if encounter != null:
		objective_label.text = encounter.objective().replace("\n", "  •  ")
	for i in players.size():
		var device: int = players[i].device
		var source := "Keyboard" if device < 0 else "Controller %d" % device
		if device >= 0 and not Input.get_connected_joypads().has(device):
			source += " — disconnected"
		var status := "%d HP" % int(players[i].health)
		if players[i].downed:
			status = "DOWN  •  Revive %d%%" % int(players[i].revive_progress / 2.0 * 100.0)
		text += "P%d  %s  •  %s  [%s]\n" % [i + 1, REALMS[i], status, source]
	roster.text = text

func on_attack(player: CharacterBody3D) -> void:
	if encounter != null:
		encounter.attack(player)

func update_camera(delta: float) -> void:
	var center := Vector3.ZERO
	for player in players:
		center += player.position
	center /= maxf(players.size(), 1)
	focus = focus.lerp(center, 1.0 - exp(-5.0 * delta))
	camera.position = focus + Vector3(20, 25, 20)
	camera.look_at(focus)
	var width := 0.0
	var height := 0.0
	for player in players:
		var relative := camera.global_basis.inverse() * (player.position - focus)
		width = maxf(width, absf(relative.x))
		height = maxf(height, absf(relative.y))
	var viewport := get_viewport().get_visible_rect().size
	var aspect := viewport.x / maxf(viewport.y, 1.0)
	var needed := maxf(24.0, maxf((width * 2.0 + 8.0) / aspect, (height * 2.0 + 7.0) / 0.65))
	camera.size = lerpf(camera.size, needed, 1.0 - exp(-5.0 * delta))

func box(size: Vector3, location: Vector3, color: Color, solid: bool) -> StaticBody3D:
	if solid and location.y >= 0.0:
		obstacles.append(Rect2(Vector2(location.x - size.x / 2.0 - 0.55, location.z - size.z / 2.0 - 0.55), Vector2(size.x + 1.1, size.z + 1.1)))
	var body := StaticBody3D.new()
	body.position = location
	add_child(body)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var collision_shape := BoxShape3D.new()
		collision_shape.size = size
		collision.shape = collision_shape
		body.add_child(collision)
	return body

func build_clearing() -> void:
	box(Vector3(48, 0.5, 48), Vector3(0, -0.25, 0), Color("263d33"), true)
	for z in [-24, 24]:
		box(Vector3(49, 2, 0.5), Vector3(0, 1, z), Color("425347"), true)
	for x in [-24, 24]:
		box(Vector3(0.5, 2, 48), Vector3(x, 1, 0), Color("425347"), true)
	# Three connected combat layers with broad center and outer flanking routes.
	box(Vector3(42, 0.02, 12), Vector3(0, 0.01, 15), Color("3b4934"), false)
	box(Vector3(42, 0.02, 14), Vector3(0, 0.01, 0), Color("304b43"), false)
	box(Vector3(42, 0.02, 12), Vector3(0, 0.01, -13), Color("45404c"), false)
	for z in [8, -5]:
		for x in [-11, 11]:
			box(Vector3(9, 1.4, 1.6), Vector3(x, 0.7, z), Color("626657"), true)
	# Ruined plinths and stump clusters make spaces to weave around.
	for point in [Vector3(-7, 0, 16), Vector3(8, 0, 15), Vector3(-16, 0, 1), Vector3(15, 0, 0), Vector3(-4, 0, -12), Vector3(5, 0, -14)]:
		box(Vector3(2.5, 1.8, 2.5), point + Vector3(0, 0.9, 0), Color("6c705e"), true)
		box(Vector3(1.3, 0.6, 1.3), point + Vector3(0, 2.1, 0), Color("8b9074"), false)
	for x in [-21, 21]:
		for z in [-15, -2, 12]:
			box(Vector3(1.7, 3.2, 1.7), Vector3(x, 1.6, z), Color("594438"), true)
			box(Vector3(3.4, 1.0, 3.4), Vector3(x, 3.6, z), Color("385a42"), false)
	for entry in [["ENTRY GROVE", 18], ["RUIN WALK / FLANKING PATHS", 2], ["CORRUPTED SANCTUM", -15]]:
		var sign := Label3D.new()
		sign.text = entry[0]
		sign.position = Vector3(0, 0.1, entry[1])
		sign.rotation_degrees.x = -90
		sign.pixel_size = 0.014
		add_child(sign)

func build_navigation() -> void:
	navigation.region = Rect2i(-24, -24, 49, 49)
	navigation.cell_size = Vector2.ONE
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(-24, 25):
		for z in range(-24, 25):
			for obstacle in obstacles:
				if obstacle.has_point(Vector2(x, z)):
					navigation.set_point_solid(Vector2i(x, z))
					break

func route_to(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := walkable_cell(from)
	var end := walkable_cell(to)
	var result := PackedVector3Array()
	for point in navigation.get_point_path(start, end, true):
		result.append(Vector3(point.x, 0, point.y))
	if result.size() > 1:
		result.remove_at(0)
	return result

func walkable_cell(point: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(roundi(point.x), -23, 23), clampi(roundi(point.z), -23, 23))
	for radius in range(0, 4):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate):
					return candidate
	return cell
