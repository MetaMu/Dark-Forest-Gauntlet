extends "res://scripts/clearing.gd"
const Puppet=preload("res://scripts/gnome_puppet.gd")
const Forest=preload("res://scripts/forest_art.gd")
const RealmEncounter=preload("res://scripts/realm_encounter.gd")
var voices: Array[AudioStreamPlayer] = []
var sound_bank: Dictionary = {}
var voice_index := 0
var ambience: AudioStreamPlayer
var party: Node
var level_id := 1
var level_title := "THE MOONLIT RUINS"
var transitioning := false

func build_environment_art() -> void:
	Forest.build(self)

func travel_to_level(id: int, auto_begin: bool = false) -> void:
	var roster_data: Array=[]
	for player in players: roster_data.append({"device":player.device,"class_id":player.class_id})
	get_tree().set_meta("campaign_roster",roster_data)
	get_tree().set_meta("campaign_auto_begin",auto_begin)
	if party!=null: get_tree().set_meta("campaign_active",party.active.duplicate())
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scenes/bellcap_cistern.tscn" if id==2 else "res://scenes/forest_encounter.tscn")

func enable_keyboard_party() -> void:
	if party!=null or encounter.state!=encounter.State.LOBBY: return
	get_tree().set_meta("keyboard_party_mode",true)
	# Reuse the existing roster, filling empty slots before assigning keyboard teams.
	for slot in range(players.size(),4): join_player(200+slot)
	for i in 4:
		players[i].class_id=i
		players[i].get_node("PlayerRing").material_override.albedo_color=COLORS[i]
	party=preload("res://scripts/keyboard_party.gd").new()
	add_child(party)
	party.setup(self)

func select_party_class(slot: int, id: int) -> void:
	if party==null or encounter.state!=encounter.State.LOBBY: return
	var previous: int=players[slot].class_id
	for member in players:
		if member.class_id==id: member.class_id=previous
	players[slot].class_id=id
	for member in players:
		member.get_node("PlayerRing").material_override.albedo_color=COLORS[member.class_id]
		for child in member.get_children():
			if child is Label3D: child.modulate=COLORS[member.class_id]

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is CanvasLayer:
			child.hide()
		if child is Label3D:
			child.hide()
		if child is WorldEnvironment:
			child.environment.ambient_light_color=Color("7e9dac")
			child.environment.ambient_light_energy=0.26
			child.environment.background_mode=Environment.BG_COLOR
			child.environment.background_color=Color("101c25")
			child.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
			child.environment.fog_enabled=true
			child.environment.fog_light_color=Color("101b24")
			child.environment.fog_density=0.004
		if child is DirectionalLight3D:
			child.light_color=Color("adcbdc")
			child.light_energy=0.45
			child.shadow_enabled=true
	build_environment_art()
	var hud=load("res://scripts/game_hud.gd").new()
	add_child(hud)
	for i in 8:
		var voice:=AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	sound_bank={
		"step":load("res://assets/vendor/kenney-impact/footstep_grass_000.ogg"),
		"attack":load("res://assets/vendor/kenney-impact/impactWood_light_000.ogg"),
		"hurt":load("res://assets/vendor/kenney-impact/impactWood_heavy_000.ogg")
		,"power":load("res://assets/vendor/kenney-impact/impactMetal_light_000.ogg")
		,"hit":load("res://assets/vendor/kenney-impact/impactWood_heavy_000.ogg")
	}
	build_navigation()
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists("res://assets/audio/forest_ambience.wav"):
		ambience=AudioStreamPlayer.new()
		ambience.stream=load("res://assets/audio/forest_ambience.wav")
		ambience.stream=ambience.stream.duplicate()
		ambience.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		ambience.stream.loop_end=352800
		ambience.volume_db=-24.0
		add_child(ambience)
		ambience.play()
	if get_tree().get_meta("keyboard_party_mode","--keyboard-party" in OS.get_cmdline_user_args()): enable_keyboard_party()
	if get_tree().has_meta("campaign_roster"):
		var saved: Array=get_tree().get_meta("campaign_roster")
		get_tree().remove_meta("campaign_roster")
		if party==null:
			for i in range(1,saved.size()): join_player(saved[i].device)
		for i in mini(players.size(),saved.size()):
			players[i].class_id=saved[i].class_id
			players[i].get_node("PlayerRing").material_override.albedo_color=COLORS[players[i].class_id]
			for child in players[i].get_children():
				if child is Label3D: child.modulate=COLORS[players[i].class_id]
	if get_tree().has_meta("campaign_active"):
		if party!=null:
			party.active=get_tree().get_meta("campaign_active")
			for team in 2: party.update_control(team)
		get_tree().remove_meta("campaign_active")
	if get_tree().get_meta("campaign_auto_begin",false):
		get_tree().remove_meta("campaign_auto_begin")
		encounter.begin.call_deferred()

func create_encounter() -> Node3D:
	return RealmEncounter.new()

func prepare_attack(player: CharacterBody3D) -> void:
	var radius: float=[4.0,11.0,7.0,8.0][player.class_id]
	var target=encounter.nearest_enemy(player.position,radius)
	if target!=null:
		var direction: Vector3=target.position-player.position
		player.last_input=Vector2(direction.x-direction.z,direction.x+direction.z).normalized()

func join_player(device: int) -> void:
	if party!=null: return
	var count:=players.size()
	super.join_player(device)
	if players.size()==count:
		return
	var player=players.back()
	player.class_id=count
	player.stepped_combat=true
	player.power_requested.connect(func(p): encounter.realm_power(p))
	player.dash_finished.connect(func(p): encounter.ember_landing(p))
	for child in player.visual.get_children(): child.hide()
	player.attack_visual.hide()
	player.attack_visual=null
	var puppet=Puppet.new()
	puppet.name="GnomePuppet"
	player.add_child(puppet)
	for child in player.get_children():
		if child is Label3D:
			child.position.y=3.8
			child.modulate=COLORS[count]
	var marker:=MeshInstance3D.new()
	var ring:=TorusMesh.new()
	ring.inner_radius=0.48;ring.outer_radius=0.54
	marker.mesh=ring
	marker.position.y=0.05
	marker.material_override=preload("res://scripts/combat_fx.gd").material(COLORS[count])
	player.add_child(marker)
	marker.name="PlayerRing"

func select_class(device: int, id: int) -> void:
	if encounter.state!=encounter.State.LOBBY:
		return
	if party!=null:
		if device in [-1,-2]: select_party_class(players.find(party.current(-device-1)),posmod(id,4))
		return
	for player in players:
		if player.device==device:
			player.class_id=posmod(id,4)
			player.get_node("PlayerRing").material_override.albedo_color=COLORS[player.class_id]
			for child in player.get_children():
				if child is Label3D: child.modulate=COLORS[player.class_id]

func _input(event: InputEvent) -> void:
	super._input(event)
	if encounter==null or encounter.state!=encounter.State.LOBBY:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_4:
			select_class(-1,event.physical_keycode-KEY_1)
		elif event.physical_keycode==KEY_T:
			enable_keyboard_party()
		elif event.physical_keycode==KEY_Q and party==null:
			select_class(-1,players[0].class_id+1)
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		for player in players:
			if player.device==event.device:
				select_class(event.device,player.class_id+(1 if event.button_index==JOY_BUTTON_RIGHT_SHOULDER else -1))

func update_camera(delta: float) -> void:
	var old_size: float=camera.size
	super.update_camera(delta)
	# Fit both the feet and labels between the HUD panels, including separated players.
	var width:=0.0
	var height:=0.0
	for player in players:
		for point in [player.position,player.position+Vector3.UP*3.8]:
			var relative: Vector3=camera.global_basis.inverse()*(point-focus)
			width=maxf(width,absf(relative.x))
			height=maxf(height,absf(relative.y))
	var viewport:=get_viewport().get_visible_rect().size
	var aspect: float=viewport.x/maxf(viewport.y,1)
	var target_size:=maxf(19.0,maxf((width*2.0+6.0)/aspect,(height*2.0+4.0)/0.65))
	camera.size=lerpf(old_size,target_size,1.0-exp(-8.0*delta))

func play_sound(id: String, volume_db: float) -> void:
	if DisplayServer.get_name() == "headless" or voices.is_empty() or not sound_bank.has(id): return
	var voice=voices[voice_index%voices.size()]
	voice_index+=1
	voice.stream=sound_bank[id]
	voice.volume_db=volume_db
	voice.pitch_scale=1.0 + float(voice_index%3-1)*0.06
	voice.play()

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
	if is_instance_valid(ambience):
		ambience.stop()
