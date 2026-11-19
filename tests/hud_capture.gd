extends "res://tests/power_design_capture.gd"
func shot(name: String) -> void:
	await frame(3)
	root.get_texture().get_image().save_png("res://artifacts/gnomish-ui/"+name+".png")
func run() -> void:
	var player:=await stage(0)
	room.encounter.realm_power(player)
	await frame(12)
	await shot("10-ember-hud")
	await clear_stage()
	await stage(0,3)
	for i in 4:
		var p=room.players[i]
		p.class_id=i;p.health=[100,72,38,18][i];p.power_cooldown=i
		p.device=-3
		p.position=Vector3(-2+i*1.2,.1,1.0)
	await shot("11-party-hud")
	root.size=Vector2i(960,540)
	await shot("12-party-hud-small")
	await clear_stage()
	print("HUD CAPTURES COMPLETE")
	quit()
