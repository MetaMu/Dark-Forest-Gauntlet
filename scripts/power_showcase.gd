extends SceneTree
## Automatic four-character showcase, also used for reproducible review captures.
var OUT := "res://artifacts/power-fx-v3/"
var room: Node3D
var demo := false
var frames_written := 0
var samples: Array[float] = []
var stats: Dictionary = {}

func _initialize() -> void:
	if "--magic-review" in OS.get_cmdline_user_args(): OUT="res://artifacts/magic-sequence/"
	if "--studio-review" in OS.get_cmdline_user_args(): OUT="res://artifacts/studio-vfx/"
	demo="--demo" in OS.get_cmdline_user_args()
	call_deferred("run")

func tick(count: int) -> void:
	for i in count:
		await process_frame
		await RenderingServer.frame_post_draw

func save(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
	print("VFX CAPTURE: ",name)

func stage(focus_class: int=-1, offset: Vector3=Vector3.ZERO) -> void:
	if is_instance_valid(room):
		room.free()
		await tick(2)
	room=load("res://scenes/forest_encounter.tscn").instantiate()
	room.set_meta("power_showcase",true)
	root.add_child(room)
	for i in 3: room.join_player(100+i)
	room.encounter.begin()
	var positions := [Vector3(-3.4,.1,2.5),Vector3(-4.5,.1,-.4),Vector3(-.3,.1,3.3),Vector3(2,.1,3.6)]
	if focus_class>=0:
		positions=[Vector3(-5,.1,4),Vector3(-3,.1,5.5),Vector3(-.5,.1,6.2),Vector3(2,.1,6.0)]
		positions[focus_class]=Vector3(-1.5,.1,1.3)
		if focus_class==1: positions[focus_class]=Vector3(-3.8,.1,1.3)
	for i in 4:
		room.players[i].position=positions[i]+offset
		room.players[i].last_input=Vector2(.707,.707)
		room.players[i].health=60 if i!=3 else 80
	var enemy_positions: Array[Vector3]=[Vector3(1.5,0,-1),Vector3(1.5,0,1.3),Vector3(4.8,0,-1.7),Vector3(3.2,0,.5)]
	for i in room.encounter.enemies.size():
		var enemy=room.encounter.enemies[i]
		enemy.position=enemy_positions[i]+offset
		enemy.health=1000;enemy.max_health=1000 # review targets survive every visual phase
		enemy.cooldown=1000;enemy.update_label()
	room.set_process(false)
	room.camera.position=Vector3(16,21,21)+offset
	room.camera.look_at(Vector3(.3,.7,1.0)+offset)
	room.camera.size=19
	await tick(15)

func loop_capture(index: int, file: String) -> void:
	await stage(index)
	room.players[index].try_power()
	await tick(([18,14,10,8] if "--studio-review" in OS.get_cmdline_user_args() else [18,6,10,8])[index])
	await save(file)
	await tick(45)

func measure(label: String, frame_count: int) -> void:
	var times: Array[float]=[]
	for i in frame_count:
		var before:=Time.get_ticks_usec()
		await tick(1)
		times.append(float(Time.get_ticks_usec()-before)/1000.0)
	times.sort()
	stats[label]={"median_ms":times[times.size()/2],"p95_ms":times[int(times.size()*.95)],"frames":frame_count}

func run() -> void:
	if not demo:
		DirAccess.make_dir_recursive_absolute(OUT+"frames")
		await loop_capture(0,"01_ember")
		await loop_capture(1,"02_ironbark")
		await loop_capture(2,"03_spore")
		await loop_capture(3,"04_light")
		await stage()
		await measure("idle_four_characters",45)
		for player in room.players: player.try_power()
		await measure("four_simultaneous_powers",45)
		stats["note"]="Observed capture frame completion spacing, fixed simulation 60 Hz; includes CPU and renderer waits, not isolated GPU timings."
		var log:=FileAccess.open(OUT+"timing.json",FileAccess.WRITE)
		log.store_string(JSON.stringify(stats,"  "));log.close()
	var repeat_count:=100000 if demo else 1
	for repeat in repeat_count:
		await stage()
		for i in 180:
			if i==15: room.players[0].try_power()
			if i==19: room.players[1].try_power()
			if i==23: room.players[2].try_power()
			if i==27: room.players[3].try_power()
			await tick(1)
			if not demo:
				if i==33: await save("05_all_four")
				if i%5==0:
					await save("frames/cast_%03d" % frames_written)
					frames_written+=1
		await tick(60)
	if not demo:
		await stage(-1,Vector3(-8,0,0))
		for player in room.players: player.try_power()
		await tick(16);await save("06_dark_ground")
		room.free();await tick(5)
		print("FOUR CLASS VFX SHOWCASE COMPLETE")
		quit()
