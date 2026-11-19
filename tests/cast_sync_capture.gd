extends "res://tests/power_design_capture.gd"
func run()->void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://artifacts/cast-sync/frames")
	var index:=0
	for id in 4:
		var actor:=await stage(id,2 if id==3 else 0)
		actor.invulnerability=100;actor.health=50
		var canvas:=CanvasLayer.new();room.add_child(canvas)
		var caption:=Label.new();caption.position=Vector2(24,105);caption.add_theme_font_size_override("font_size",22);canvas.add_child(caption)
		for i in 120:
			if i==8:actor.try_power()
			var phase:="READY"
			if actor.pending_power:phase="GATHERING MAGIC"
			elif actor.cast_elapsed>=actor.CAST_RELEASE:phase="RELEASE / RECOVERY"
			caption.text=["EMBER HOLLOW","IRONBARK","SPORE GROVE","LIGHT REALM"][id]+" — "+phase
			await frame(2)
			root.get_texture().get_image().save_png("res://artifacts/cast-sync/frames/frame-%04d.png"%index)
			index+=1
		await clear_stage()
	print("CAST REVIEW: ",index," frames")
	quit()
