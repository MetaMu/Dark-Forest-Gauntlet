extends SceneTree
const Controls=preload("res://scripts/local_input.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func frames(count: int=3) -> void:
	for i in count: await physics_frame
func press(team: int, action: String) -> void: Input.action_press(Controls.action_name(-1-team,action))
func release(team: int, action: String) -> void: Input.action_release(Controls.action_name(-1-team,action))
func run() -> void:
	var room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	DirAccess.make_dir_recursive_absolute("res://artifacts/keyboard-coop")
	Controls.settings_path="res://artifacts/keyboard-coop/test-keyboard.cfg"
	var old_key:=Controls.key_for(-1,"attack")
	check(not Controls.rebind(-1,"attack",Controls.key_for(-2,"attack")),"Remapping rejects another player's assigned key")
	check(not Controls.rebind(-1,"attack",KEY_ESCAPE),"Remapping preserves the pause key")
	check(Controls.rebind(-1,"attack",KEY_F8),"A free key can be rebound")
	var event:=InputEventKey.new();event.physical_keycode=KEY_F8;event.keycode=KEY_F8;event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events();await frames(2)
	check(Controls.attack(-1) and not Controls.attack(-2),"Remapped physical key reaches only its owner")
	var up:=InputEventKey.new();up.physical_keycode=KEY_F8;up.keycode=KEY_F8;up.pressed=false
	Input.parse_input_event(up);Input.flush_buffered_events();await frames(2)
	var config:=ConfigFile.new();config.load(Controls.settings_path)
	check(config.get_value("keys",Controls.action_name(-1,"attack"))==KEY_F8,"Custom binding is saved to configuration")
	Controls.rebind(-1,"attack",old_key);Controls.settings_path="user://keyboard.cfg"
	room.enable_keyboard_party();await frames()
	var party=room.party
	check(room.players.size()==4 and party.teams.size()==2,"Two humans each own two characters")
	check(room.players[0].controlled and not room.players[1].controlled and room.players[2].controlled and not room.players[3].controlled,"Only one character per team receives keyboard input")
	await frames(8)
	check(room.players[2].get_node("GnomePuppet").marker.text.begins_with("P2"),"World marker identifies the human owner rather than roster slot")
	room.select_party_class(0,3)
	check(room.players[0].class_id==3 and room.players[3].class_id==0,"Lobby selection swaps characters without duplicates")
	room.select_party_class(0,0)
	room.join_player(99)
	check(room.players.size()==4,"Controller join cannot steal a keyboard team")
	press(0,"right");press(1,"up")
	check(Controls.movement(-1)==Vector2.RIGHT and Controls.movement(-2)==Vector2.UP,"Both keyboards move independently at the same time")
	release(0,"right")
	check(Controls.movement(-1)==Vector2.ZERO and Controls.movement(-2)==Vector2.UP,"Releasing P1 input leaves P2 held input intact")
	release(1,"up")
	room.encounter.begin()
	for enemy in room.encounter.enemies:
		enemy.set_physics_process(false);enemy.position=Vector3(18,0,-18)
	for i in 4: room.players[i].position=Vector3(-3+i*2,.1,2)
	var first=party.current(0);var second=party.current(1)
	var start1: Vector3=first.position;var start2: Vector3=second.position
	press(0,"right");press(1,"left");await frames(12)
	release(0,"right");release(1,"left")
	check(first.position.x>start1.x and second.position.x<start2.x,"Two active gnomes physically move in different directions")
	first.health=57;first.power_cooldown=4
	press(0,"switch");await frames()
	check(party.current(0)!=first and party.current(1)==second,"P1 switch changes only P1 control")
	var switched=party.current(0);await frames(10)
	check(party.current(0)==switched,"Holding switch does not repeatedly toggle")
	release(0,"switch");await frames()
	check(first.health==57 and first.power_cooldown>3,"Switch preserves the old character health and cooldown")
	press(0,"power");await frames();var cooldown: float=switched.power_cooldown
	check(cooldown>0 and first.power_cooldown<4,"Power belongs to the controlled gnome")
	press(0,"switch");await frames();release(0,"switch")
	check(first.power_cooldown<4,"Held power cannot cast again on a switch")
	release(0,"power");await frames()
	press(1,"power");await frames();release(1,"power")
	check(second.power_cooldown>0,"P2 has an independent power button")
	var companion=party.teams[0][1-party.active[0]]
	first.position=Vector3(0,.1,2);companion.position=Vector3(-5,.1,2)
	var distance: float=companion.position.distance_to(first.position)
	await frames(45)
	check(companion.position.distance_to(first.position)<distance-1,"Companion navigates toward its own leader")
	var prior_power: float=companion.power_cooldown
	await frames(12)
	check(companion.power_cooldown<=prior_power,"Companion does not spend special powers")
	var heart=room.encounter.enemies[0]
	heart.position=companion.position+Vector3(0,0,-3);heart.health=1000
	await frames(65)
	check(heart.health<1000,"Companion uses basic attacks against a visible nearby enemy")
	heart.position=Vector3(18,0,-18)
	first.invulnerability=0;first.take_damage(1000);await frames()
	check(party.current(0)==companion and companion.controlled,"Downing the leader transfers control to the living partner")
	check(not party.switch_member(0),"Cannot switch control onto a downed partner")
	first.position=Vector3(0,.1,2);companion.position=Vector3(1,.1,2);companion.invulnerability=0
	press(0,"revive");await frames(130);release(0,"revive")
	check(not first.downed,"Active partner can revive the fallen gnome")
	check(not first.controlled,"Revival does not steal control from the current gnome")
	paused=true
	check(not party.switch_member(0),"Pause blocks character switching")
	paused=false
	party.current(0).position=Vector3(-11,.1,5)
	first.position=Vector3(-11,.1,11)
	await frames(300)
	check(first.position.distance_to(party.current(0).position)<3.3,"Companion follows around a solid ruin wall")
	room.queue_free();await frames(6)
	room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	await frames(4)
	check(room.party!=null and room.players.size()==4,"Returning to selection retains paired keyboard mode")
	room.queue_free();set_meta("keyboard_party_mode",false);await frames(6)
	room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	await frames(4)
	check(room.party==null and room.players.size()==1,"Solo mode can be restored without retained companions")
	room.queue_free();await frames(6)
	print("KEYBOARD RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
