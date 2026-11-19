extends CanvasLayer
const UI=preload("res://scripts/gnomish_ui.gd")
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
var bars: Array[TextureProgressBar] = []
var player_cards: Array[Control] = []
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
var interface_root: Control
var banner: Control
var shade: ColorRect

func panel_style() -> StyleBox:
	return UI.scroll()

func label(text: String, size: int, color: Color = Color("34291d")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_color_override("font_color",Color.WHITE)
	if size>=22: node.add_theme_font_override("font",UI.HEADING)
	node.add_theme_font_size_override("font_size",size)
	node.modulate = color
	return node

func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.icon=UI.SEAL;node.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
	node.add_theme_constant_override("icon_max_width",16)
	node.custom_minimum_size.y = 42
	node.pressed.connect(action)
	return node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	room = get_parent()
	var layout := Control.new()
	layout.theme=UI.theme()
	interface_root=layout
	layout.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	layout.size=Vector2(1280,720)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	var top:=Control.new();banner=top
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_bottom=105
	top.mouse_filter=Control.MOUSE_FILTER_IGNORE;layout.add_child(top)
	for rect in [Rect2(12,-7,370,114),Rect2(828,-7,440,114)]:
		var plaque:=TextureRect.new();plaque.texture=preload("res://assets/ui/gnomish/quest-plaque.png")
		plaque.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;plaque.position=rect.position;plaque.size=rect.size
		plaque.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(plaque)
	var game_title=label("DARK FOREST GAUNTLET",18,Color("382719"))
	game_title.add_theme_font_override("font",UI.HEADING);game_title.position=Vector2(49,31);game_title.size=Vector2(298,23)
	game_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;top.add_child(game_title)
	var place=label(room.level_title,12,Color("5c4b2f"));place.position=Vector2(49,53);place.size=Vector2(298,18)
	place.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;top.add_child(place)
	level_button=button("VISIT BELLCAP CISTERN" if room.level_id==1 else "RETURN TO THE RUINS",func(): room.travel_to_level(2 if room.level_id==1 else 1))
	level_button.position=Vector2(42,91);level_button.add_theme_font_size_override("font_size",12);top.add_child(level_button)
	objective=label("",15,Color("40301d"));objective.position=Vector2(875,29);objective.size=Vector2(345,44)
	objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;objective.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;top.add_child(objective)
	lobby=PanelContainer.new()
	lobby.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	lobby.offset_left=-490; lobby.offset_right=-24; lobby.offset_top=-265; lobby.offset_bottom=325
	lobby.add_theme_stylebox_override("panel",panel_style())
	layout.add_child(lobby)
	var choices:=VBoxContainer.new()
	choices.add_theme_constant_override("separation",9)
	lobby.add_child(choices)
	var choice_title=label("CHOOSE YOUR GNOME",25)
	choice_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;choices.add_child(choice_title)
	lobby_hint=label("P1: 1–4 or Q    Controllers: LB / RB",14,Color("53613b"))
	choices.add_child(lobby_hint)
	mode_button=button("TWO PLAYERS + COMPANIONS  [T]",func():
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
	choices.add_child(button("BEGIN THE JOURNEY  [Enter / Y]",func(): room.encounter.begin()))
	join_hint=label("Controller Start joins • Up to four gnomes",13)
	join_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	choices.add_child(join_hint)
	cards=HBoxContainer.new()
	cards.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cards.offset_left=20;cards.offset_right=-20;cards.offset_top=-132;cards.offset_bottom=-32
	cards.alignment=BoxContainer.ALIGNMENT_CENTER;cards.add_theme_constant_override("separation",6)
	layout.add_child(cards)
	for i in 4:
		var card=preload("res://scripts/player_hud_card.gd").new();cards.add_child(card)
		player_cards.append(card);names.append(card.name_label);bars.append(card.bar);power_labels.append(card.power_label)
	help=label("WASD / stick  Move    F / Space / X  Attack    G / Shift / B  Power    Hold E / A  Revive    Esc  Pause",13,Color("bfcbb0"))
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	help.offset_left=24; help.offset_right=-24; help.offset_top=-32; help.offset_bottom=-4
	help.add_theme_color_override("font_shadow_color",Color("132018"));help.add_theme_constant_override("shadow_offset_x",1);help.add_theme_constant_override("shadow_offset_y",1)
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(help)
	shade=ColorRect.new();shade.color=Color(0.02,.035,.025,.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layout.add_child(shade);shade.hide()
	modal=PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left=-260;modal.offset_right=260;modal.offset_top=-295;modal.offset_bottom=295
	modal.add_theme_stylebox_override("panel",panel_style())
	layout.add_child(modal)
	var menu:=VBoxContainer.new()
	menu.add_theme_constant_override("separation",12)
	modal.add_child(menu)
	modal_title=label("PAUSED",28)
	modal_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(modal_title)
	resume_button=button("RESUME",toggle_pause)
	menu.add_child(resume_button)
	restart_button=button("CHOOSE YOUR GNOMES",restart)
	menu.add_child(restart_button)
	next_level_button=button("CONTINUE TO LEVEL TWO",func(): room.travel_to_level(2))
	menu.add_child(next_level_button);next_level_button.hide()
	menu.add_child(label("MASTER VOLUME",13))
	volume=HSlider.new();volume.min_value=0;volume.max_value=100;volume.value=70
	volume.value_changed.connect(set_volume)
	menu.add_child(volume)
	menu.add_child(button("TOGGLE FULLSCREEN  [F11]",toggle_fullscreen))
	menu.add_child(button("KEYBOARD CONTROLS",func(): modal.hide();keyboard_settings.show()))
	menu.add_child(button("QUIT GAME",func(): get_tree().quit()))
	menu.add_child(label("Woodland art & sound • Kenney and friends",12,Color("53613b")))
	modal.hide()
	keyboard_settings=preload("res://scripts/keyboard_settings.gd").new()
	layout.add_child(keyboard_settings);keyboard_settings.hide()
	keyboard_settings.visibility_changed.connect(func():
		if not keyboard_settings.visible and get_tree().paused: modal.show())
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
	var viewport_size:=get_viewport().get_visible_rect().size
	var ui_scale:=minf(viewport_size.x/1280.0,viewport_size.y/720.0)
	interface_root.scale=Vector2.ONE*ui_scale
	interface_root.position=(viewport_size-Vector2(1280,720)*ui_scale)*.5
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
	var menu_open:=modal.visible or keyboard_settings.visible or celebration.visible
	shade.visible=modal.visible or keyboard_settings.visible
	banner.visible=not menu_open
	cards.visible=not menu_open and state!=room.encounter.State.LOBBY
	help.visible=not menu_open and state!=room.encounter.State.LOBBY
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
		names[i].text=TITLES[player.class_id]
		player_cards[i].health_text.text=status
		if paired:
			names[i].text=TITLES[player.class_id]
			names[i].add_theme_font_size_override("font_size",12)
		names[i].modulate=Color.WHITE
		bars[i].value=player.health
		player_cards[i].update_emblem(player.class_id,player.team_id+1 if paired else i+1,room.COLORS[player.class_id],1.0-player.power_cooldown/player.POWER_COOLDOWNS[player.class_id],player.downed)
		var power_key: String=preload("res://scripts/local_input.gd").key_label(player.device,"power") if player.device in [-1,-2] else "B"
		if player.device==-1: power_key=preload("res://scripts/local_input.gd").key_label(-1,"power")
		power_labels[i].text="%s  ·  %s" % [POWERS[player.class_id],"DOWN" if player.downed else (("[%s]" % power_key) if player.power_cooldown<=0.0 else "%.1fs" % player.power_cooldown)]
		if paired and not player.downed:
			power_labels[i].text="%s · %s" % [POWERS[player.class_id],("[%s]" % preload("res://scripts/local_input.gd").key_label(player.device,"power")) if player.controlled and player.power_cooldown<=0 else ("FOLLOWING" if not player.controlled and player.power_cooldown<=0 else "%.1fs" % player.power_cooldown)]
	for i in 4:
		if paired:
			class_buttons[i].text="P%d · %s  [%s]\nClick to change character" % [room.players[i].team_id+1,TITLES[room.players[i].class_id],"CONTROL" if room.players[i].controlled else "FOLLOW"]
			class_buttons[i].add_theme_stylebox_override("normal",UI.button_style("selected" if room.players[i].controlled else "normal"))
		else:
			class_buttons[i].add_theme_stylebox_override("normal",UI.button_style("selected" if room.players[0].class_id==i else "normal"))
	if room.transitioning: return
	if state==room.encounter.State.WON and room.level_id==2:
		modal.hide()
		if not celebration.visible: celebration.open()
		return
	if state in [room.encounter.State.WON,room.encounter.State.LOST] and not modal.visible and not keyboard_settings.visible and not celebration.visible:
		modal.show()
		modal_title.text="CLEARING RESTORED" if state==room.encounter.State.WON else "THE FOREST PREVAILS"
		if state==room.encounter.State.WON and room.level_id==2: modal_title.text="CISTERN CLEANSED"
		next_level_button.visible=state==room.encounter.State.WON and room.level_id==1
		resume_button.hide()
		restart_button.grab_focus()
