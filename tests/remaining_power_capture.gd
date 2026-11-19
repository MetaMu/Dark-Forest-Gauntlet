extends "res://tests/power_design_capture.gd"

func run() -> void:
	for id in [2,3]:
		if "--spore-only" in OS.get_cmdline_user_args() and id!=2: continue
		var title:="spore" if id==2 else "light"
		var out:="res://artifacts/"+title+"-upgrade/"
		DirAccess.make_dir_recursive_absolute(out+"frames")
		var player:=await stage(id,0 if id==2 else 2)
		player.position=Vector3(-.7,.1,1)
		for enemy in room.encounter.enemies:
			enemy.health=1000;enemy.max_health=1000;enemy.cooldown=1000;enemy.move_speed=0
			enemy.set_physics_process(true);enemy.update_label()
		if id==3:
			room.players[1].position=Vector3(-2.0,.1,2.3);room.players[1].health=40
			room.players[2].position=Vector3(0,.1,3);room.players[2].invulnerability=0
			room.players[2].take_damage(1000)
			player.health=65
		await frame(8)
		var count:=280 if id==2 else 100
		var stride:=4 if id==2 else 2
		for i in count:
			if i==12: player.try_power()
			await physics_frame
			await RenderingServer.frame_post_draw
			if i%stride==0: root.get_texture().get_image().save_png(out+"frames/"+title+"_%03d.png" % (i/stride))
			if i==24: root.get_texture().get_image().save_png(out+"cast.png")
			if i==55: root.get_texture().get_image().save_png(out+"sustain.png")
		await frame(90)
		print(title.to_upper()," CAPTURE COMPLETE; surviving effects: ",get_nodes_in_group("realm_vfx").size())
		await clear_stage()
	quit()
