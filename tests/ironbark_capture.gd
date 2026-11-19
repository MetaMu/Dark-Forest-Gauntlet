extends "res://tests/power_design_capture.gd"

func run() -> void:
	var out:="res://artifacts/ironbark-upgrade/"
	DirAccess.make_dir_recursive_absolute(out+"frames")
	var player:=await stage(1)
	for enemy in room.encounter.enemies:
		enemy.health=1000;enemy.max_health=1000;enemy.update_label()
	await frame(8)
	for i in 100:
		if i==12: player.try_power()
		await physics_frame
		await RenderingServer.frame_post_draw
		if i%2==0: root.get_texture().get_image().save_png(out+"frames/ironbark_%03d.png" % (i/2))
		if i==20: root.get_texture().get_image().save_png(out+"volley.png")
		if i==27: root.get_texture().get_image().save_png(out+"impact.png")
		if i==48: root.get_texture().get_image().save_png(out+"ironbarks.png")
	await frame(80)
	print("IRONBARK CAPTURE COMPLETE; surviving effects: ",get_nodes_in_group("realm_vfx").size())
	await clear_stage()
	quit()
