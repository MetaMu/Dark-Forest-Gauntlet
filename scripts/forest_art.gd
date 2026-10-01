extends RefCounted
## Blender-built ruin modules and verified CC0 props; visual layer only.
const RUINS := "res://assets/environment/moonlit-ruins/"
const PROPS := "res://assets/vendor/quaternius-fantasy/"
const ATLAS_CHEST := "res://assets/owner/atlas/gnome_chest_hinged.glb"
const ChestInteraction = preload("res://scripts/atlas_chest.gd")
static var cache: Dictionary = {}

static func grade(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		for i in node.get_surface_override_material_count():
			var source=node.get_active_material(i)
			if source is StandardMaterial3D:
				var material: StandardMaterial3D=source.duplicate()
				material.albedo_color*=tint
				node.set_surface_override_material(i,material)
	for child in node.get_children(): grade(child,tint)

static func bounds(node: Node3D, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var combined := AABB()
	var next := transform * node.transform
	if node is MeshInstance3D: combined = next * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var box := bounds(child,next)
			if box.size.length_squared() > 0:
				combined = box if combined.size.length_squared() == 0 else combined.merge(box)
	return combined

static func model(parent: Node3D, path: String, point: Vector3, height: float = 0.0, angle: float = 0.0) -> Node3D:
	if not cache.has(path): cache[path] = load(path)
	var node: Node3D = cache[path].instantiate()
	if path.begins_with(RUINS) and not "staff" in path and not "bow" in path:
		grade(node,Color(.50,.58,.52))
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.position=point; pivot.rotation.y=angle
	pivot.add_child(node)
	if height>0:
		var box := bounds(node)
		var factor := height/maxf(box.size.y,0.01)
		node.scale*=factor
		node.position-=Vector3(box.get_center().x,box.position.y,box.get_center().z)*factor
	return pivot

static func ruin(parent: Node3D, asset: String, point: Vector3, angle: float=0.0) -> Node3D:
	return model(parent,RUINS+asset+".glb",point,0,angle)

static func prop(parent: Node3D, asset: String, point: Vector3, height: float, angle: float=0.0) -> Node3D:
	return model(parent,PROPS+asset+".glb",point,height,angle)

static func lantern(room: Node3D, point: Vector3, color: Color=Color("ffc077")) -> void:
	prop(room,"lantern_wall",point+Vector3(.6,1.84,-.5),0.9)
	var light := OmniLight3D.new()
	light.position=point+Vector3(.6,2.2,-.3)
	light.light_color=color;light.light_energy=1.7;light.omni_range=5.0
	room.add_child(light)
	var mote:=MeshInstance3D.new()
	var sphere:=SphereMesh.new();sphere.radius=.075;sphere.height=.2
	mote.mesh=sphere;mote.position=light.position
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=color;material.emission_enabled=true;material.emission=color
	mote.material_override=material;room.add_child(mote)

static func build(room: Node3D) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=48731
	for body in room.get_children():
		if not body is StaticBody3D: continue
		for child in body.get_children():
			if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
			var size: Vector3=child.mesh.size
			if body.position.y<0:
				var ground:=ShaderMaterial.new()
				ground.shader=load("res://shaders/forest_ground.gdshader")
				for entry in [["forest_color","forest_leaves_02_diffuse"],["forest_normal","forest_leaves_02_nor_gl"],["cobble_color","cobblestone_floor_04_diff"],["cobble_normal","cobblestone_floor_04_nor_gl"]]:
					ground.set_shader_parameter(entry[0],load("res://assets/vendor/polyhaven-forest/"+entry[1]+"_1k.jpg"))
				child.material_override=ground
				var landscape:=MeshInstance3D.new()
				var plane:=PlaneMesh.new();plane.size=Vector2(100,100)
				landscape.mesh=plane;landscape.position.y=-.035
				landscape.material_override=ground
				room.add_child(landscape)
				continue
			child.hide()
			var foot:=Vector3(0,-body.position.y,0)
			if body.name=="PlaceholderRootGate": ruin(body,"iron_gate",foot)
			elif size.y<0.1 or size.y==0.6 or size.y==1.0: continue
			elif size.x==2.5:
				ruin(body,"ruined_plinth",foot)
				lantern(room,body.position+foot)
			elif size.x==9.0: ruin(body,"ruined_wall",foot)
			elif size.x==1.7:
				ruin(body,"ancient_tree_%d" % rng.randi_range(0,2),foot,rng.randf()*TAU).scale=Vector3.ONE*.65
			elif size.x>20 or size.z>20:
				for i in 6:
					var p:=Vector3(-22.5+i*9,0,0) if size.x>20 else Vector3(0,0,-22.5+i*9)
					ruin(body,"ruined_wall",foot+p,0 if size.x>20 else PI/2).scale.y=.6
	for edge in [-1,1]:
		for i in 11:
			var v: float=-26+i*5.2
			for point in [Vector3(edge*27.0,0,v),Vector3(v,0,edge*27.0)]:
				ruin(room,"ancient_tree_%d" % (i%3),point,rng.randf()*TAU)
	for i in 85:
		var x:=rng.randf_range(-22,22);var z:=rng.randf_range(-22,22)
		if absf(x)<4.5 or (absf(z+11)<3.3 and absf(x)<15): continue
		var fern:=ruin(room,"fern",Vector3(x,.025,z),rng.randf()*TAU)
		fern.scale=Vector3.ONE*rng.randf_range(.65,1.2)
	for point in [Vector3(-12,0,-11),Vector3(12,0,-11)]:
		ruin(room,"ritual_ring",point)
		lantern(room,point+Vector3(-2.8,0,-1),Color("b88bdf"))
		ruin(room,"ruined_plinth",point+Vector3(-2.8,0,-1))
	ruin(room,"sanctum_arch",Vector3(0,0,-20))
	var chest := model(room,ATLAS_CHEST,Vector3(-7.4,1.83,16.4),.7,PI/4)
	var chest_interaction := ChestInteraction.new()
	chest.add_child(chest_interaction)
	chest_interaction.setup(room,chest)
	prop(room,"potion_1",Vector3(8.55,1.83,15),.35)
	prop(room,"book_7",Vector3(7.55,1.83,15),.25)
	prop(room,"barrel",Vector3(-8,0,17),1.1)
	prop(room,"crate_wooden",Vector3(-7,0,17),.75,.2)
	prop(room,"shield_wooden",Vector3(-7.6,.15,17.1),.8,.5)
	prop(room,"weaponstand",Vector3(8,0,14.7),1.8)
	prop(room,"sword_bronze",Vector3(8.5,.2,14.7),1.2,.8)
	for point in [Vector3(-18,0,8),Vector3(18,0,-5),Vector3(-5,0,-20),Vector3(5,0,-20)]:
		ruin(room,"rubble",point,rng.randf()*TAU)
