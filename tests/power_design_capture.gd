extends SceneTree
## Deterministic GPU captures for power VFX design review.
const OUT := "res://artifacts/power-design/"
var room: Node3D

func _initialize() -> void:
	call_deferred("run")

func frame(count: int = 1) -> void:
	for i in count:
		await physics_frame
	await RenderingServer.frame_post_draw

func save(name: String) -> void:
	await frame(1)
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("POWER CAPTURE: ", name)

func stage(class_id: int, ally_count: int = 0) -> CharacterBody3D:
	room = load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	for i in ally_count:
		room.join_player(100 + i)
	room.select_class(-1, class_id)
	room.encounter.begin()
	for enemy in room.encounter.enemies:
		enemy.set_physics_process(false)
	# A clean central lane shows the caster, target and affected radius.
	var player: CharacterBody3D = room.players[0]
	player.position = Vector3(-2.0, 0.1, 1.0)
	player.last_input = Vector2(0.707, 0.707) # +X in world space
	var positions := [Vector3(2.4,0,1),Vector3(4.2,0,1.6),Vector3(3.4,0,-.4),Vector3(5.1,0,.1)]
	for i in mini(room.encounter.enemies.size(), positions.size()):
		room.encounter.enemies[i].position = positions[i]
	room.set_process(false)
	room.camera.position = Vector3(13,18,18)
	room.camera.look_at(Vector3(1.3,1.0,.7))
	room.camera.size = 13.5
	await frame(10)
	return player

func clear_stage() -> void:
	room.free()
	room = null
	await frame(4)

func ember() -> void:
	var player := await stage(0)
	room.encounter.realm_power(player)
	# The dash takes 0.18 seconds. Capture immediately after its fire impact.
	await frame(12)
	await save("01_ember_dash_burst_mid_power")
	await clear_stage()

func ironbark() -> void:
	var player := await stage(1)
	room.encounter.realm_power(player)
	# Three arrows are midway between the ranger and the target.
	await frame(8)
	await save("02_ironbark_piercing_volley_mid_power")
	await clear_stage()

func spore() -> void:
	var player := await stage(2)
	room.encounter.realm_power(player)
	# Preserve the snare ring, cast burst and target labels in the same frame.
	await frame(3)
	await save("03_spore_grove_root_snare_mid_power")
	await clear_stage()

func light_realm() -> void:
	var player := await stage(3, 2)
	var wounded: CharacterBody3D = room.players[1]
	wounded.position = Vector3(.2,.1,2.2)
	wounded.health = 42
	room.encounter.realm_power(player)
	await frame(3)
	await save("04_light_realm_sanctuary_mid_power")
	await clear_stage()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await ember()
	await ironbark()
	await spore()
	await light_realm()
	print("POWER DESIGN CAPTURES COMPLETE")
	quit()
