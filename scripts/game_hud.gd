extends CanvasLayer
const TITLES := ["EMBER HOLLOW", "IRONBARK", "SPORE GROVE", "LIGHT REALM"]
const DESCRIPTIONS := ["Flame sweep • close combat", "Ranger bolt • auto-aim", "Spore cloud • slows enemies", "Radiant bolt • heals nearby allies"]
const POWERS := ["DASH BURST", "PIERCING VOLLEY", "ROOT SNARE", "SANCTUARY"]
var room: Node3D
var objective: Label
var lobby: PanelContainer
var modal: PanelContainer
var modal_title: Label
var resume_button: Button
var restart_button: Button
var cards: HBoxContainer
var bars: Array[ProgressBar] = []
var fills: Array[StyleBoxFlat] = []
var power_labels: Array[Label] = []
var names: Array[Label] = []
var class_buttons: Array[Button] = []
var volume: HSlider
var settings := ConfigFile.new()
var help: Label
var mode_button: Button
var lobby_hint: Label
var keyboard_settings: PanelContainer
var join_hint: Label
var level_button: Button
var next_level_button: Button
var celebration: Control

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.041,0.049,0.94)
	style.border_color = Color("8d7953")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

func label(text: String, size: int, color: Color = Color("ece4cd")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",size)
	node.modulate = color
	return node

func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.pressed.connect(action)
	return node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	room = get_parent()
	var layout := Control.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left=20; top.offset_right=-20; top.offset_top=16; top.offset_bottom=90
	top.add_theme_stylebox_override("panel",panel_style())
	layout.add_child(top)
	var header := HBoxContainer.new()
	top.add_child(header)
	var title := VBoxContainer.new()
	header.add_child(title)
	title.add_child(label("DARK FOREST GAUNTLET",22))
	title.add_child(label(room.level_title,12,Color("c7af7d")))
	level_button=button("LEVEL 2: BELLCAP CISTERN" if room.level_id==1 else "BACK TO LEVEL 1",func(): room.travel_to_level(2 if room.level_id==1 else 1))
	level_button.add_theme_font_size_override("font_size",12);header.add_child(level_button)
	objective=label("",16)
	objective.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(objective)
	lobby=PanelContainer.new()
	lobby.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	lobby.offset_left=-430; lobby.offset_right=-24; lobby.offset_top=-235; lobby.offset_bottom=225
	lobby.add_theme_stylebox_override("panel",panel_style())
	layout.add_child(lobby)
	var choices:=VBoxContainer.new()
	choices.add_theme_constant_override("separation",10)
	lobby.add_child(choices)
	choices.add_child(label("CHOOSE YOUR GNOME",22))
	lobby_hint=label("P1: 1–4 or Q    Controllers: LB / RB",14,Color("a9bd91"))
	choices.add_child(lobby_hint)
	mode_button=button("TWO KEYBOARD PLAYERS + COMPANIONS [T]",func():
		if room.party==null: room.enable_keyboard_party()
		else:
			get_tree().set_meta("keyboard_party_mode",false)
			restart())
	mode_button.add_theme_font_size_override("font_size",13)
	choices.add_child(mode_button)
	for i in 4:
		var option = button("%s\n%s • %s" % [TITLES[i],DESCRIPTIONS[i].split(" • ")[0],POWERS[i].capitalize()],func():
			if room.party!=null: room.select_party_class(i,(room.players[i].class_id+1)%4)
			else: room.select_class(-1,i))
		option.add_theme_font_size_override("font_size",15)
		option.custom_minimum_size.y=48
		choices.add_child(option)
		class_buttons.append(option)
	choices.add_child(button("ENTER THE CLEARING  [Enter / Y]",func(): room.encounter.begin()))
	join_hint=label("Controller Start joins • Up to four gnomes",13)
	choices.add_child(join_hint)
	cards=HBoxContainer.new()
	cards.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cards.offset_left=20; cards.offset_right=-20; cards.offset_top=-122; cards.offset_bottom=-35
	cards.add_theme_constant_override("separation",10)
	layout.add_child(cards)
	for i in 4:
		var card:=PanelContainer.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",panel_style())
		cards.add_child(card)
		var stack:=VBoxContainer.new()
		card.add_child(stack)
		var name_label=label("",14)
		stack.add_child(name_label)
		names.append(name_label)
		var bar:=ProgressBar.new()
		bar.custom_minimum_size.y=9
		bar.show_percentage=false
		var background:=StyleBoxFlat.new()
		background.bg_color=Color("29382f")
		background.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background",background)
		var fill:=StyleBoxFlat.new()
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill",fill)
		fills.append(fill)
		stack.add_child(bar)
		bars.append(bar)
		var power_label=label("",12,Color("ddcf94"))
		stack.add_child(power_label)
		power_labels.append(power_label)
	help=label("WASD / stick  Move    F / Space / X  Attack    G / Shift / B  Power    Hold E / A  Revive    Esc  Pause",13,Color("bfcbb0"))
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	help.offset_left=24; help.offset_top=-29; help.offset_bottom=-6
	layout.add_child(help)
	modal=PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left=-230;modal.offset_right=230;modal.offset_top=-205;modal.offset_bottom=205
	modal.add_theme_stylebox_override("panel",panel_style())
	layout.add_child(modal)
	var menu:=VBoxContainer.new()
	menu.add_theme_constant_override("separation",12)
	modal.add_child(menu)
	modal_title=label("PAUSED",28)
	menu.add_child(modal_title)
	resume_button=button("RESUME",toggle_pause)
	menu.add_child(resume_button)
	restart_button=button("RETURN TO GNOME SELECTION",restart)
	menu.add_child(restart_button)
	next_level_button=button("CONTINUE TO LEVEL TWO",func(): room.travel_to_level(2))
	menu.add_child(next_level_button);next_level_button.hide()
	menu.add_child(label("MASTER VOLUME",13))
	volume=HSlider.new();volume.min_value=0;volume.max_value=100;volume.value=70
	volume.value_changed.connect(set_volume)
	menu.add_child(volume)
	menu.add_child(button("TOGGLE FULLSCREEN  [F11]",toggle_fullscreen))
	menu.add_child(button("KEYBOARD CONTROLS",func(): keyboard_settings.show()))
	menu.add_child(button("QUIT GAME",func(): get_tree().quit()))
	menu.add_child(label("Forest models & SFX: Kenney • CC0",12,Color("a9bd91")))
	modal.hide()
	keyboard_settings=preload("res://scripts/keyboard_settings.gd").new()
	layout.add_child(keyboard_settings);keyboard_settings.hide()
	celebration=preload("res://scripts/victory_scroll.gd").new()
	layout.add_child(celebration);celebration.hide()
	celebration.replay_requested.connect(func(): room.travel_to_level(1))
	celebration.quit_requested.connect(func(): get_tree().quit())
	settings.load("user://settings.cfg")
	volume.value=settings.get_value("audio","master",70.0)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume.value/100.0,0.0001)))

func set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(value/100.0,0.0001)))
	settings.set_value("audio","master",value)
	settings.save("user://settings.cfg")

func _input(event: InputEvent) -> void:
	if keyboard_settings.visible:
		if event is InputEventKey:
			if event.pressed and not event.echo: keyboard_settings.capture_key(event)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_ESCAPE:
			toggle_pause()
		elif event.physical_keycode==KEY_F11:
			toggle_fullscreen()
	elif event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START and room.encounter.state!=room.encounter.State.LOBBY:
		toggle_pause()

func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func toggle_pause() -> void:
	if room.encounter.state in [room.encounter.State.WON,room.encounter.State.LOST]:
		return
	get_tree().paused=not get_tree().paused
	modal.visible=get_tree().paused
	modal_title.text="PAUSED"
	resume_button.visible=true
	if get_tree().paused:
		resume_button.grab_focus()

func restart() -> void:
	get_tree().paused=false
	get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	var paired: bool=room.party!=null
	if paired:
		join_hint.text="Two people • One keyboard • Companions follow and attack"
		mode_button.text="RETURN TO SOLO / CONTROLLER MODE"
		var input=preload("res://scripts/local_input.gd")
		lobby_hint.text="Click a slot to change • %s / %s swaps control" % [input.key_label(-1,"switch"),input.key_label(-2,"switch")]
		var summaries: Array[String]=[]
		for team in 2:
			var device: int=-1-team
			summaries.append("P%d: %s/%s/%s/%s move · %s attack · %s power · %s switch · %s revive" % [team+1,input.key_label(device,"up"),input.key_label(device,"left"),input.key_label(device,"down"),input.key_label(device,"right"),input.key_label(device,"attack"),input.key_label(device,"power"),input.key_label(device,"switch"),input.key_label(device,"revive")])
		help.text="    |    ".join(summaries)+"    |    Esc settings"
		help.add_theme_font_size_override("font_size",12)
	else:
		var keys=preload("res://scripts/local_input.gd")
		help.text="%s/%s/%s/%s or stick: move    %s/Space/X: attack    %s/Shift/B: power    Hold %s/A: revive    Esc: pause" % [keys.key_label(-1,"up"),keys.key_label(-1,"left"),keys.key_label(-1,"down"),keys.key_label(-1,"right"),keys.key_label(-1,"attack"),keys.key_label(-1,"power"),keys.key_label(-1,"revive")]
	var state: int=room.encounter.state
	level_button.visible=state==room.encounter.State.LOBBY
	lobby.visible=state==room.encounter.State.LOBBY and not get_tree().paused
	if state==room.encounter.State.LOBBY:
		objective.text="Two keyboard players • Two gnomes each" if paired else "Gather your party • Controller Start to join"
	elif state==room.encounter.State.COMBAT:
		objective.text="Root Hearts  %d / 2   •   Rootlings  %d" % [room.encounter.count_enemies(true),room.encounter.count_enemies(false)]
		if room.level_id==2: objective.text="Anchors %d / 3 · Enemies %d · Dodge orange marks!" % [room.encounter.count_enemies(true),room.encounter.count_enemies(false)]
	elif state==room.encounter.State.REWARD:
		objective.text="Eat the Golden Pear to enter level two" if room.level_id==1 else "Collect the Golden Pear • Northern shrine"
	elif state==room.encounter.State.EXIT:
		objective.text="Bring every surviving gnome through the north gate"
	if room.has_meta("power_showcase"):
		objective.text="POWER SHOWCASE • Four realm characters • Automatic casts"
	for i in 4:
		cards.get_child(i).visible=i<room.players.size()
		if i>=room.players.size(): continue
		var player=room.players[i]
		var status="%d HP" % int(player.health)
		if player.downed: status="DOWN • Revive %d%%" % int(player.revive_progress/2*100)
		elif player.device>=0 and not Input.get_connected_joypads().has(player.device) and not room.has_meta("power_showcase"): status="Disconnected"
		names[i].text="P%d  %s  ·  %s" % [i+1,TITLES[player.class_id],status]
		if paired:
			names[i].text="P%d %s %s · %s" % [player.team_id+1,"▶" if player.controlled else "+",TITLES[player.class_id],status]
			names[i].add_theme_font_size_override("font_size",12)
		names[i].modulate=room.COLORS[player.class_id]
		bars[i].value=player.health
		fills[i].bg_color=room.COLORS[player.class_id]
		power_labels[i].text="%s  ·  %s" % [POWERS[player.class_id],"DOWN" if player.downed else ("READY [Shift / B]" if player.power_cooldown<=0.0 else "%.1fs" % player.power_cooldown)]
		if paired and not player.downed:
			power_labels[i].text="%s · %s" % [POWERS[player.class_id],("READY [%s]" % preload("res://scripts/local_input.gd").key_label(player.device,"power")) if player.controlled and player.power_cooldown<=0 else ("FOLLOWING" if not player.controlled and player.power_cooldown<=0 else "%.1fs" % player.power_cooldown)]
	for i in 4:
		if paired:
			class_buttons[i].text="P%d · %s  [%s]\nClick to change character" % [room.players[i].team_id+1,TITLES[room.players[i].class_id],"CONTROL" if room.players[i].controlled else "FOLLOW"]
			class_buttons[i].modulate=room.COLORS[room.players[i].class_id]
		else:
			class_buttons[i].modulate=Color("efd18a") if room.players[0].class_id==i else Color.WHITE
	if room.transitioning: return
	if state==room.encounter.State.WON and room.level_id==2:
		modal.hide()
		if not celebration.visible: celebration.open()
		return
	if state in [room.encounter.State.WON,room.encounter.State.LOST] and not modal.visible:
		modal.show()
		modal_title.text="CLEARING RESTORED" if state==room.encounter.State.WON else "THE FOREST PREVAILS"
		if state==room.encounter.State.WON and room.level_id==2: modal_title.text="CISTERN CLEANSED"
		next_level_button.visible=state==room.encounter.State.WON and room.level_id==1
		resume_button.hide()
		restart_button.grab_focus()
