extends SceneTree
## A recorded input-driven encounter. No damage, cooldown or AI overrides.
const Controls=preload("res://scripts/local_input.gd")
var frame:=0
var room: Node3D
func _initialize() -> void: call_deferred("start")
func start() -> void:
	room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	room.enable_keyboard_party();room.encounter.begin()
	# Start the short recording at the combat area rather than spending it walking in.
	for i in 4: room.players[i].position=Vector3(-9+i*1.5,.1,-6)
	room.focus=Vector3(-7,0,-7);room.update_camera(1)
	for i in 900:
		frame=i
		for team in 2:
			var actor=room.party.current(team)
			var target=room.encounter.nearest_enemy(actor.position,40)
			var heading:=Vector3.ZERO
			if target!=null:
				var offset: Vector3=target.position-actor.position;offset.y=0
				var ideal: float=[2.5,5.0,3.5,4.0][actor.class_id]
				if offset.length()>ideal: heading=offset.normalized()
				elif offset.length()<1.8: heading=-offset.normalized()
			elif room.encounter.state in [room.encounter.State.REWARD,room.encounter.State.EXIT]:
				var destination:=Vector3(0,0,-17) if room.encounter.state==room.encounter.State.REWARD else Vector3(0,0,-23)
				var route: PackedVector3Array=room.route_to(actor.position,destination)
				if not route.is_empty(): heading=(route[0]-actor.position).normalized()
			var move:=Vector2(heading.x-heading.z,heading.x+heading.z).normalized()
			set_action(team,"left",move.x<-.3);set_action(team,"right",move.x>.3)
			set_action(team,"up",move.y<-.3);set_action(team,"down",move.y>.3)
			set_action(team,"attack",i>75)
			set_action(team,"power",i in ([35,310,640] if team==0 else [65,345,700]))
			set_action(team,"switch",i in ([235,560] if team==0 else [270,590]))
		await process_frame
		await RenderingServer.frame_post_draw
		if i in [90,350,650]:
			root.get_texture().get_image().save_png("res://artifacts/gameplay-video/frame_%03d.png"%i)
	for team in 2:
		for action in Controls.ACTIONS: set_action(team,action,false)
	print("RECORDED GAMEPLAY: 900 frames, normal combat rules, two keyboard teams")
	quit()
func set_action(team: int, action: String, held: bool) -> void:
	if held: Input.action_press(Controls.action_name(-1-team,action))
	else: Input.action_release(Controls.action_name(-1-team,action))
