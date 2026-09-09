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

func _ready() -> void:
	box(Vector3(28, 0.5, 24), Vector3(0, -0.25, 0), Color("263d33"), true)
	box(Vector3(29, 2, 0.5), Vector3(0, 1, -12), Color("425347"), true)
	box(Vector3(29, 2, 0.5), Vector3(0, 1, 12), Color("425347"), true)
	box(Vector3(0.5, 2, 24), Vector3(-14, 1, 0), Color("425347"), true)
	box(Vector3(0.5, 2, 24), Vector3(14, 1, 0), Color("425347"), true)
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
	encounter = Encounter.new()
	encounter.name = "Encounter"
	add_child(encounter)
	update_camera(1.0)

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
	player.collision_mask = 1
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
	ring.inner_radius = 1.9
	ring.outer_radius = 2.1
	pulse.mesh = ring
	pulse.position.y = 0.15
	pulse.material_override = material
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
	player.position = Vector3((slot % 2) * 2 - 1, 0.1, floori(slot / 2.0) * 2 + 4)
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
