extends "res://scripts/power_showcase.gd"
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/power-fx-final")
	await stage()
	var failures:=0
	for enemy in room.encounter.enemies:
		enemy.health=10000;enemy.max_health=10000;enemy.cooldown=1000;enemy.move_speed=0
	for player in room.players: player.invulnerability=100
	for round_index in 3:
		for player in room.players:
			player.power_cooldown=0;player.try_power()
		for i in 190:
			await tick(1)
			if get_nodes_in_group("power_lights").size()>6: failures+=1
			if round_index==0 and i==78:
				root.get_texture().get_image().save_png("res://artifacts/power-fx-final/all-four.png")
	await tick(300)
	var clean:=get_nodes_in_group("realm_vfx").is_empty()
	if not clean: failures+=1
	print("ALL POWER SMOKE: three overlapping four-player casts; light budget respected; cleanup=",clean,"; failures=",failures)
	room.free();await tick(4)
	quit(1 if failures else 0)
