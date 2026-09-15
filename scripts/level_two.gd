extends "res://scripts/polished_clearing.gd"

func _init() -> void:
	level_id=2;level_title="LEVEL TWO · THE BELLCAP CISTERN"

func create_encounter() -> Node3D:
	return preload("res://scripts/cistern_encounter.gd").new()

func build_environment_art() -> void:
	preload("res://scripts/cistern_art.gd").build(self)

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.ambient_light_color=Color("a6c9b9");child.environment.ambient_light_energy=.38
			child.environment.fog_light_color=Color("133938");child.environment.fog_density=.006
		if child is DirectionalLight3D:
			child.light_color=Color("b4d2bb");child.light_energy=.62

func build_clearing() -> void:
	box(Vector3(48,.5,48),Vector3(0,-.25,0),Color("354e4a"),true)
	for z in [-24,24]: box(Vector3(49,2,.5),Vector3(0,1,z),Color("485f58"),true)
	for x in [-24,24]: box(Vector3(.5,2,48),Vector3(x,1,0),Color("485f58"),true)
	box(Vector3(5,1.3,8),Vector3(0,.65,1),Color("385d50"),true)
	box(Vector3(1.6,1.8,10),Vector3(-9,.9,-3),Color("576f62"),true)
	box(Vector3(1.6,1.8,8),Vector3(9,.9,-7),Color("576f62"),true)
	for x in [-8,8]: box(Vector3(6,1.4,1.6),Vector3(x,.7,10),Color("617165"),true)
	for point in [Vector3(-16,0,7),Vector3(16,0,10),Vector3(-4,0,-10),Vector3(5,0,-13)]:
		box(Vector3(2.5,1.8,2.5),point+Vector3.UP*.9,Color("64796b"),true)
