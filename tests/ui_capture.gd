extends SceneTree
var room: Node3D
var hud: CanvasLayer
var out:="res://artifacts/gnomish-ui/"
func _initialize() -> void: call_deferred("run")
func tick(count: int=5) -> void:
	for i in count:
		await process_frame
		await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await tick()
	root.get_texture().get_image().save_png(out+name+".png")
	print("UI CAPTURE: ",name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	room=load("res://scenes/forest_encounter.tscn").instantiate();root.add_child(room)
	for child in room.get_children():
		if child.get_script()==load("res://scripts/game_hud.gd"): hud=child
	await tick(20)
	await capture("01-selection")
	room.enable_keyboard_party();await tick()
	await capture("02-party-selection")
	room.encounter.begin();await tick(10)
	await capture("03-combat")
	hud.toggle_pause();await capture("04-pause")
	hud.modal.hide();hud.keyboard_settings.show();await capture("05-controls")
	hud.keyboard_settings.hide();hud.toggle_pause()
	room.encounter.finish(room.encounter.State.LOST);await capture("06-defeat")
	room.level_id=2;room.encounter.state=room.encounter.State.WON
	hud.modal.hide();hud.celebration.open();hud.celebration.manual_time=1.4
	await capture("07-victory")
	room.encounter.state=room.encounter.State.COMBAT
	hud.celebration.hide();root.size=Vector2i(960,540)
	hud.keyboard_settings.show();await capture("08-controls-small")
	hud.keyboard_settings.hide();hud.modal.show();await capture("09-pause-small")
	room.free();await tick();quit()
