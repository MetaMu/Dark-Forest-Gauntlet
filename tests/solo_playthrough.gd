extends SceneTree
const LocalInput=preload("res://scripts/local_input.gd")
var held: Dictionary={}
var results: Array[Dictionary]=[]
var use_powers:=false

func _initialize() -> void: call_deferred("run")

func press(code: Key, down: bool) -> void:
	if held.get(code,false)==down: return
	held[code]=down
	var event:=InputEventKey.new()
	event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func steer(direction: Vector3) -> void:
	var screen:=Vector2(direction.x-direction.z,direction.x+direction.z).normalized()
	press(KEY_D,screen.x>0.3);press(KEY_A,screen.x < -0.3)
	press(KEY_S,screen.y>0.3);press(KEY_W,screen.y < -0.3)

func run() -> void:
	use_powers="--powers" in OS.get_cmdline_user_args()
	var failures:=0
	for id in 4:
		var room=load("res://scenes/forest_encounter.tscn").instantiate()
		root.add_child(room)
		room.select_class(-1,id)
		var player=room.players[0]
		room.encounter.begin()
		var frames:=0
		var route: PackedVector3Array=[]
		while frames<60*180 and room.encounter.state not in [room.encounter.State.WON,room.encounter.State.LOST]:
			var target: Vector3=room.encounter.reward_position
			if room.encounter.state==room.encounter.State.COMBAT:
				var best:=INF
				for enemy in room.encounter.enemies:
					if is_instance_valid(enemy) and not enemy.dead:
						var score: float=enemy.position.distance_to(player.position)
						if score<best:
							best=score;target=enemy.position
				var preferred: float=[2.5,6.0,4.0,5.0][id]
				if best<preferred and room.encounter.visible_to(player.position,target):
					target=player.position
			elif room.encounter.state==room.encounter.State.EXIT:
				target=Vector3(0,0,-23)
			if frames%12==0:
				route=room.route_to(player.position,target)
			while not route.is_empty() and player.position.distance_to(route[0])<0.7: route.remove_at(0)
			var direction:=Vector3.ZERO
			if target.distance_to(player.position)>0.6:
				direction=(route[0] if not route.is_empty() else target)-player.position
			steer(direction)
			press(KEY_SPACE,room.encounter.state==room.encounter.State.COMBAT)
			press(KEY_SHIFT,use_powers and room.encounter.state==room.encounter.State.COMBAT and player.power_cooldown<=0 and target.distance_to(player.position)<8.0)
			await physics_frame
			frames+=1
		var won: bool=room.encounter.state==room.encounter.State.WON
		if not won: failures+=1
		var result={"class":id,"won":won,"seconds":frames/60.0,"health":player.health,"state":room.encounter.state,"position":str(player.position)}
		results.append(result)
		print("SOLO: ",JSON.stringify(result))
		for code in [KEY_D,KEY_A,KEY_S,KEY_W,KEY_SPACE,KEY_SHIFT]:press(code,false)
		room.free()
		await process_frame
	var report:=FileAccess.open("res://artifacts/solo-powers.json" if use_powers else "res://artifacts/solo-playthrough.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(results,"\t"))
	print("SOLO RESULT: %d / 4 wins" % (4-failures))
	quit(failures)
