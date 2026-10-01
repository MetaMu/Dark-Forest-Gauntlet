extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	var room = load("res://scenes/forest_encounter.tscn").instantiate()
	root.add_child(room)
	room.encounter.begin()
	await process_frame
	var rootling: CharacterBody3D
	var heart: CharacterBody3D
	for enemy in room.encounter.enemies:
		if enemy.is_heart and heart == null:
			heart = enemy
		elif not enemy.is_heart and rootling == null:
			rootling = enemy
	check(rootling != null and heart != null, "Encounter has a Rootling and Root Heart")
	if rootling == null or heart == null:
		quit(1)
		return
	rootling.set_physics_process(false)
	check(rootling.has_combat_clips(), "Rootling loaded its combat rig")
	check(heart.has_combat_clips(), "Root Heart uses its Atlas combat rig")
	var visual = rootling.creature_visual
	var player: AnimationPlayer = visual.combat_player
	if player == null:
		quit(1)
		return
	for clip in ["Idle", "WalkInPlace", "AttackSwipe", "HitFlinch", "Death"]:
		check(player.has_animation(clip), "Imported clip: " + clip)
	check(player.get_animation("Idle").loop_mode == Animation.LOOP_LINEAR, "Idle loops")
	check(player.get_animation("WalkInPlace").loop_mode == Animation.LOOP_LINEAR, "Walk loops")
	rootling.velocity = Vector3(1, 0, 0)
	await process_frame
	check(visual.current_clip == "WalkInPlace", "Moving Rootling plays walk")
	rootling.velocity = Vector3.ZERO
	await process_frame
	check(visual.current_clip == "Idle", "Stopped Rootling plays idle")
	rootling.windup = 0.55
	visual.begin_attack(0.55)
	check(visual.current_clip == "AttackSwipe", "Attack plays swipe")
	rootling.windup = -1.0
	rootling.stagger = 0.5
	visual.begin_hit()
	check(visual.current_clip == "HitFlinch", "Damage plays flinch")
	rootling.stagger = 0.0
	rootling.take_damage(10000.0)
	check(rootling.dead and visual.current_clip == "Death", "Fatal damage plays death")
	check(rootling.collision_layer == 0 and rootling.death_time_remaining > 0.0, "Dead Rootling no longer collides and remains for death pose")
	rootling.set_physics_process(true)
	for i in 100:
		await physics_frame
	check(not is_instance_valid(rootling), "Death pose completes and Rootling is removed")
	room.queue_free()
	await process_frame
	print("ROOTLING ANIMATION RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
