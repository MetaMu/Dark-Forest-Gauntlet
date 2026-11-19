extends SceneTree
var checks:=0
var failures:=0
var room: Node3D
var hud: CanvasLayer
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS: " if ok else "FAIL: ",message)
func tick(n: int=5) -> void:
	for i in n: await process_frame
func fits(node: Control) -> bool:
	var rect:=node.get_global_rect()
	return root.get_visible_rect().grow(1).encloses(rect)
func run() -> void:
	room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	for child in room.get_children():
		if child.get_script()==load("res://scripts/game_hud.gd"): hud=child
	await tick(15)
	var ui=load("res://scripts/gnomish_ui.gd")
	check(ui.HEADING.get_font_name()=="Gnomish Elder","Original Gnomish Elder font loads")
	check(ui.PAPER.get_image().get_pixel(0,0).a==0.0,"Scroll artwork has a genuinely transparent exterior")
	check(hud.lobby.visible and fits(hud.lobby),"Selection parchment fits the viewport")
	check(not hud.cards.visible,"Lobby avoids redundant combat HUD cards")
	hud.class_buttons[1].pressed.emit();await tick()
	check(room.players[0].class_id==1,"Styled class button selects the requested gnome")
	room.join_player(100);await tick()
	check(hud.power_labels[1].text.contains("[B]"),"Controller hints use B without reading keyboard bindings")
	room.enable_keyboard_party();await tick()
	check(fits(hud.lobby),"Four-slot party selection fits its parchment")
	room.encounter.begin();await tick()
	check(not hud.lobby.visible and hud.cards.visible,"Beginning combat switches to the compact HUD")
	check(hud.player_cards[0].FRAME.get_image().get_pixel(0,0).a==0.0,"Illustrated player frame has transparent edges")
	check(hud.bars[0] is TextureProgressBar,"Health uses a live textured fill")
	var all_fit:=true
	for card in hud.player_cards: all_fit=all_fit and fits(card) and card.size.x<310
	check(all_fit,"All four illustrated cards fit without stretching")
	room.players[0].health=37;await tick()
	check(hud.bars[0].value==37,"Illustrated bar tracks injured health")
	check(hud.player_cards[0].health_text.text.contains("37"),"Health number matches its fill")
	room.players[0].power_cooldown=2;await tick()
	check(hud.player_cards[0].cooldown_bar.value<100,"Recharge meter tracks power cooldown")
	var enemy=room.encounter.enemies[0]
	check(enemy.health_bar!=null and not enemy.label.text.contains("▰"),"Enemies use illustrated health meters instead of block text")
	enemy.take_damage(enemy.max_health)
	check(not enemy.health_bar.visible,"Defeated enemy health meter disappears")
	hud.toggle_pause();await tick()
	check(paused and hud.modal.visible and not hud.banner.visible,"Pause displays a focused scroll over the forest")
	hud.modal.hide();hud.keyboard_settings.show();await tick()
	check(fits(hud.keyboard_settings) and not hud.modal.visible,"Controls replace the pause scroll without stacking")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	hud.keyboard_settings.capture_key(escape);await tick()
	check(not hud.keyboard_settings.visible and hud.modal.visible and paused,"Closing controls returns to the paused menu")
	hud.resume_button.pressed.emit();await tick()
	check(not paused and not hud.modal.visible,"Styled Resume button resumes play")
	root.size=Vector2i(960,540);hud.toggle_pause();await tick()
	check(fits(hud.modal),"Pause scroll fits a 960 by 540 window")
	hud.modal.hide();hud.keyboard_settings.show();await tick()
	var buttons_fit:=true
	for button in hud.keyboard_settings.buttons: buttons_fit=buttons_fit and fits(button)
	check(fits(hud.keyboard_settings) and buttons_fit,"Every remapping button fits the smaller window")
	hud.keyboard_settings.hide();hud.toggle_pause()
	room.encounter.finish(room.encounter.State.LOST);await tick()
	check(hud.modal.visible and not hud.resume_button.visible and fits(hud.modal),"Defeat scroll remains readable and cannot resume a lost encounter")
	room.level_id=2;room.encounter.state=room.encounter.State.WON;await tick()
	check(hud.celebration.visible and not hud.modal.visible,"Final victory uses the celebration parchment")
	room.free();paused=false;await tick()
	print("UI RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
