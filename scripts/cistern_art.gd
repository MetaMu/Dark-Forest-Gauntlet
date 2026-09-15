extends RefCounted
const Forest=preload("res://scripts/forest_art.gd")

static func form(parent: Node3D, mesh: Mesh, point: Vector3, color: Color, glow: bool=false) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=mesh;node.position=point
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.85
	if glow: mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=.65
	node.material_override=mat;parent.add_child(node);return node

static func mushroom(parent: Node3D, point: Vector3, size: float, enemy: bool=false) -> Node3D:
	var group:=Node3D.new();parent.add_child(group);group.position=point;group.scale=Vector3.ONE*size
	var stem:=CylinderMesh.new();stem.top_radius=.22;stem.bottom_radius=.4;stem.height=1.2;stem.radial_segments=9
	form(group,stem,Vector3.UP*.6,Color("857f59"))
	var cap:=SphereMesh.new();cap.radius=.85;cap.height=.7;cap.radial_segments=16;cap.rings=8
	var crown=form(group,cap,Vector3.UP*1.45,Color("9076a2") if not enemy else Color("638632"))
	var skin:=ShaderMaterial.new();skin.shader=load("res://shaders/fungal_cap.gdshader")
	skin.set_shader_parameter("base_color",Color("9076a2") if not enemy else Color("729b36"));crown.material_override=skin
	var gill:=TorusMesh.new();gill.inner_radius=.62;gill.outer_radius=.79;gill.rings=16;gill.ring_segments=6
	form(group,gill,Vector3.UP*1.24,Color("7aded0") if not enemy else Color("cff076"),true)
	for i in 8:
		var dot:=SphereMesh.new();dot.radius=.07;dot.height=.10
		var a:=i*2.399;var r:=.27+float(i%3)*.14
		form(group,dot,Vector3(cos(a)*r,1.69,sin(a)*r),Color("b3f5df") if not enemy else Color("e5ff90"),true)
	if enemy:
		for x in [-.22,.22]:
			var eye:=SphereMesh.new();eye.radius=.10;eye.height=.14
			form(group,eye,Vector3(x,.92,.34),Color("ffe785"),true)
		var mortar:=CylinderMesh.new();mortar.top_radius=.20;mortar.bottom_radius=.13;mortar.height=.48;mortar.radial_segments=8
		form(group,mortar,Vector3.UP*1.9,Color("d6d981"))
	return group

static func build(room: Node3D) -> void:
	var ground:=ShaderMaterial.new();ground.shader=load("res://shaders/cistern_ground.gdshader")
	ground.set_shader_parameter("stone",load("res://assets/vendor/polyhaven-forest/cobblestone_floor_04_diff_1k.jpg"))
	ground.set_shader_parameter("normal_tex",load("res://assets/vendor/polyhaven-forest/cobblestone_floor_04_nor_gl_1k.jpg"))
	var outside:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(110,110)
	outside.mesh=plane;outside.position.y=-.045;outside.material_override=ground;room.add_child(outside)
	for body in room.get_children():
		if not body is StaticBody3D: continue
		for child in body.get_children():
			if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
			var size: Vector3=child.mesh.size
			if body.position.y<0: child.material_override=ground;continue
			child.hide()
			if body.name=="PlaceholderRootGate": Forest.ruin(body,"iron_gate",Vector3(0,-body.position.y,0));continue
			if size.x==2.5: Forest.ruin(body,"ruined_plinth",Vector3(0,-body.position.y,0));continue
			var length: float=maxf(size.x,size.z)
			var count:=maxi(1,ceili(length/8.8))
			for i in count:
				var along: float=(float(i)+.5)*length/count-length*.5
				var point:=Vector3(along,-body.position.y,0) if size.x>size.z else Vector3(0,-body.position.y,along)
				var wall=Forest.ruin(body,"ruined_wall",point,0 if size.x>size.z else PI/2)
				wall.scale=Vector3(length/count/9.0,size.y/1.4,maxf(.6,minf(size.x,size.z)/1.6))
	for side in [-1,1]:
		for i in 9:
			var z: float=-21+i*5
			mushroom(room,Vector3(side*22.2,0,z),1.4+float(i%3)*.35)
			if i%3==0:
				var lamp:=OmniLight3D.new();lamp.position=Vector3(side*21,2,z);lamp.omni_range=7
				lamp.light_color=Color("72caba");lamp.light_energy=1.0;room.add_child(lamp)
	for point in [Vector3(-16,0,-9),Vector3(15,0,-5),Vector3(0,0,-14)]:
		Forest.ruin(room,"ritual_ring",point)
		mushroom(room,point+Vector3(-2.5,0,-1),1.3)
		mushroom(room,point+Vector3(2.5,0,-1),.9)
	Forest.ruin(room,"sanctum_arch",Vector3(0,0,-20))
	for point in [Vector3(-16,0,7),Vector3(16,0,10),Vector3(-4,0,-10),Vector3(5,0,-13)]:
		Forest.lantern(room,point,Color("ffa968"))
	for i in 12:
		var z: float=-17+i*2.6
		for x in [-7.9,7.9]: mushroom(room,Vector3(x,0,z),.35+float(i%3)*.08)
	for side in [-1,1]:
		for i in 12:
			Forest.ruin(room,"fern",Vector3(side*(20+float(i%2)),.02,-19+i*3.4),i*1.73).scale=Vector3.ONE*.8
