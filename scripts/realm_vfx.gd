extends Node3D
## Visual-only effects. Lifetimes and status observers never deal damage.
## Elemental Sandbox motifs adapted natively for Godot: https://github.com/achrefelouafi/HandCastAbilityThreeJS
## The source is MIT licensed; these adaptations do not import its Three.js, GLSL, or hand-tracking runtime.
const TEXTURES := "res://assets/vendor/power-fx/"
const GROUND = preload("res://shaders/power_ground.gdshader")
const PARTICLE = preload("res://shaders/power_sprite.gdshader")
static var textures: Dictionary = {}
var duration := 1.0
var age := 0.0
var parts: Array[Dictionary] = []
var grounds: Array[ShaderMaterial] = []
var subject: Node3D
var mode := ""
var last_point := Vector3.ZERO
var sample_clock := 0.0
var samples := 0
var dash_ended := false
var ghost_count := 0
var trail_points: Array[Vector3] = []
var glint_clock := 0.0
var trail_mesh: MeshInstance3D
var trail_color := Color.WHITE
var trail_width := .15
var nature_trail := false
var root_geometry: Node3D
var root_materials: Array[ShaderMaterial] = []
var encounter_owner: Node
var light_tracks: Array[Dictionary] = []
const MAX_POWER_LIGHTS := 6
const STUDIO_VFX_REVISION := "2026-09-14-crystal-wake-1"

# Original six-sided geometry: facets remain visible from the isometric camera.
func crystal(point: Vector3, height: float, width: float, color: Color, life: float, velocity: Vector3=Vector3.ZERO, delay: float=0.0) -> MeshInstance3D:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in 6:
		var a:=float(side)*TAU/6.0;var b:=float(side+1)*TAU/6.0
		var left:=Vector3(cos(a)*width,0,sin(a)*width)
		var right:=Vector3(cos(b)*width,0,sin(b)*width)
		var shade: Color=Color.WHITE*([.65,.85,1.0,.78,.55,.72][side]);shade.a=1.0
		surface.set_color(shade)
		for vertex in [left,Vector3.UP*height*.78,right,right,Vector3.DOWN*height*.22,left]: surface.add_vertex(vertex)
	surface.generate_normals()
	var node:=MeshInstance3D.new();node.mesh=surface.commit()
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true;material.albedo_color=color
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node);node.position=point;node.add_to_group("spell_crystals")
	parts.append({"node":node,"material":material,"color":color,"life":life,"delay":delay,"velocity":velocity,"growth":.65,"origin":point})
	return node

# Tower Defense's colored corona / bright core, adapted to depth-tested 3D.
func light_pulse(color: Color, radius: float, peak: float, life: float=.65, delay: float=0.0) -> void:
	var live:=0
	for lamp in get_tree().get_nodes_in_group("power_lights"):
		if not lamp.is_queued_for_deletion(): live+=1
	if live>=MAX_POWER_LIGHTS: return
	var lamp:=OmniLight3D.new();lamp.position=Vector3.UP*1.35;lamp.omni_range=radius
	lamp.shadow_enabled=false;lamp.light_energy=0;lamp.light_color=color
	add_child(lamp);lamp.add_to_group("power_lights")
	light_tracks.append({"node":lamp,"color":color,"peak":peak,"life":life,"delay":delay})

static func light_envelope(t: float) -> float:
	if t<0 or t>=1: return 0
	if t<.12: return lerpf(0.0,1.0,smoothstep(0.0,.12,t))
	if t<.3: return lerpf(1.0,.35,smoothstep(.12,.3,t))
	if t<.48: return lerpf(.35,.52,smoothstep(.3,.48,t))
	return .52*(1.0-smoothstep(.48,1.0,t))

func stroke(a: Vector3, b: Vector3, color: Color, width: float, life: float, delay: float=0) -> void:
	var direction:=b-a
	if direction.length()<.001: return
	for layer in 2:
		var node:=MeshInstance3D.new();var shape:=CylinderMesh.new()
		shape.top_radius=width*(3.2 if layer==0 else .55);shape.bottom_radius=shape.top_radius
		shape.height=direction.length();shape.radial_segments=5;shape.rings=1;node.mesh=shape
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
		var tint:=Color(color,.2) if layer==0 else Color(color.lerp(Color.WHITE,.78),.9)
		mat.albedo_color=tint;node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node);node.position=(a+b)*.5;node.quaternion=Quaternion(Vector3.UP,direction.normalized())
		parts.append({"node":node,"material":mat,"color":tint,"life":life,"delay":delay,"velocity":Vector3.ZERO,"growth":1.0,"origin":node.position})

func arc(a: Vector3, b: Vector3, color: Color, life: float, delay: float=0) -> void:
	var last:=a;var direction:=b-a;var side:=direction.cross(Vector3.UP).normalized()
	if side.length()<.1: side=Vector3.RIGHT
	for i in range(1,7):
		var t:=float(i)/6
		var point:=a+direction*t+side*sin(i*12.9898)*.18*sin(t*PI)
		stroke(last,point,color,.032,life,delay)
		if i in [2,4]: stroke(point,point+side*(.25 if i==2 else -.35)+Vector3.UP*.18,color,.017,life*.8,delay)
		last=point

static func cast_flare(player: Node3D, color: Color) -> void:
	var rig=player.get_node_or_null("GnomePuppet")
	var origin: Vector3=rig.cast_origin() if rig!=null and rig.has_method("cast_origin") else player.global_position+Vector3.UP*1.1
	var fx=make(player,origin-Vector3.UP*1.1,.45)
	# Spore and Sanctuary own their larger ground light; avoid doubling them.
	if player.class_id in [0,1]: fx.light_pulse(color,4.0,2.6,.42)
	fx.sprite("light_02",Vector3.UP*1.1,Vector2(1.4,1.4),Color(color,.55),.35,Vector3.ZERO,0,.25)
	fx.sprite("spotlight_1",Vector3.UP*1.1,Vector2(.4,.4),Color(1,1,.95,.9),.16,Vector3.ZERO,.025,.2)
	for i in 5:
		var a:=float(i)*TAU/5
		var outside:=Vector3(cos(a),.5,sin(a))*.8+Vector3.UP*.8
		fx.stroke(outside,outside.lerp(Vector3.UP*1.1,.65),color,.025,.25,float(i)*.012)

static func make(parent: Node3D, point: Vector3, life: float, tag: String="") -> Node3D:
	var fx=load("res://scripts/realm_vfx.gd").new()
	fx.duration=life;fx.mode=tag
	var cursor: Node=parent
	while cursor!=null:
		if cursor.get("state")!=null:
			fx.encounter_owner=cursor;break
		if cursor.get("encounter")!=null:
			fx.encounter_owner=cursor.encounter;break
		cursor=cursor.get_parent()
	parent.add_child(fx);fx.global_position=point
	fx.add_to_group("realm_vfx")
	return fx

static func texture(name: String) -> Texture2D:
	if not textures.has(name): textures[name]=load(TEXTURES+name+".png")
	return textures[name]

func sprite(tex: String, point: Vector3, size: Vector2, color: Color, life: float, velocity: Vector3=Vector3.ZERO, delay: float=0.0, growth: float=1.4, additive: bool=true, ground: bool=false) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	var quad:=QuadMesh.new();quad.size=size;mesh.mesh=quad
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture=texture(tex);mat.albedo_color=color
	mat.billboard_mode=BaseMaterial3D.BILLBOARD_DISABLED if ground else BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test=false
	mesh.material_override=mat
	var animated_material: Material=mat
	if additive:
		var particle:=ShaderMaterial.new();particle.shader=preload("res://shaders/ember_flame.gdshader") if tex=="flame_01" else PARTICLE
		particle.set_shader_parameter("mask_texture",texture(tex))
		particle.set_shader_parameter("tint",color)
		particle.set_shader_parameter("billboard",not ground)
		mesh.material_override=particle;animated_material=particle
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh);mesh.position=point
	if ground: mesh.rotation.x=-PI/2
	parts.append({"node":mesh,"material":animated_material,"color":color,"life":life,"delay":delay,"velocity":velocity,"growth":growth,"origin":point,"flame":tex=="flame_01" and additive})
	return mesh

func ground_pattern(radius: float, color: Color, style: int, strength: float=1.0) -> void:
	var mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2.ONE*radius*2
	mesh.mesh=plane;mesh.position.y=.055
	var mat:=ShaderMaterial.new();mat.shader=GROUND
	mat.set_shader_parameter("tint",color);mat.set_shader_parameter("style",style);mat.set_shader_parameter("intensity",strength)
	mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh);grounds.append(mat)

func spray(color: Color, count: int, radius: float, life: float, tex: String="spark_05", lift: float=1.8) -> void:
	for i in count:
		var angle:=i*2.399963
		var direction:=Vector3(cos(angle),.25+float(i%3)*.18,sin(angle))
		var start:=Vector3(direction.x,.1,direction.z)*radius*.18
		var velocity:=Vector3(direction.x*radius*.8,lift+float(i%4)*.4,direction.z*radius*.8)
		var size:=.13+float(i%3)*.065
		sprite(tex,start,Vector2(size,size*1.8),color,life,velocity,float(i%3)*.025,.3)

static func dash(parent: Node3D, player: Node3D) -> void:
	var fx=make(parent,Vector3.ZERO,.65,"dash")
	fx.subject=player;fx.last_point=player.global_position
	fx.afterimage()

func afterimage() -> void:
	# Skin baking requires a rendering backend; headless gameplay tests have none.
	if DisplayServer.get_name()=="headless": return
	if ghost_count>=3 or not is_instance_valid(subject): return
	var puppet=subject.get_node_or_null("GnomePuppet")
	if puppet==null: return
	var ghost=make(get_parent(),subject.global_position,.40,"ember_ghost")
	ghost.add_to_group("ember_afterimages")
	# Bake the current skin pose; snapshots must not keep following live bones.
	for source in puppet.find_children("*","MeshInstance3D",true,false):
		if not source.is_visible_in_tree() or source.mesh==null: continue
		var copy:=MeshInstance3D.new()
		copy.mesh=source.bake_mesh_from_current_skeleton_pose() if source.skin!=null else source.mesh
		if copy.mesh==null: copy.free();continue
		var mat:=StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color=Color(1,.42,.08,.38)
		copy.material_override=mat
		copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost.add_child(copy);copy.global_transform=source.global_transform
		ghost.parts.append({"node":copy,"material":mat,"color":mat.albedo_color,"life":.4,"delay":0.0,"velocity":Vector3.ZERO,"growth":1.0,"origin":copy.position,"base_scale":copy.scale})
	# Retain support for the older cut-paper showcase without changing its pose.
	for source in puppet.sprites:
		var copy:=Sprite3D.new()
		copy.texture=source.texture.duplicate();copy.pixel_size=source.pixel_size
		copy.offset=source.offset;copy.flip_h=source.flip_h
		copy.modulate=Color(1,.42,.08,.38);ghost.add_child(copy)
		copy.global_transform=source.global_transform
		ghost.parts.append({"node":copy,"color":copy.modulate,"life":.4,"delay":0.0,"velocity":Vector3.ZERO,"growth":1.0,"origin":copy.position,"base_scale":copy.scale})
	ghost_count+=1

func dash_sample() -> void:
	if dash_ended or not is_instance_valid(subject) or subject.downed: return
	var current: Vector3=subject.global_position
	if subject.dash_time<=0.0: dash_ended=true
	var distance:=current.distance_to(last_point)
	if distance<.08: return
	# Distance-based emission avoids gaps at low frame rates and piles at high rates.
	var count:=clampi(int(ceil(distance/.28)),1,12)
	for i in count:
		var point:=last_point.lerp(current,float(i+1)/count)
		var fire=make(get_parent(),point,.65,"ember_wake")
		var height:=.8+float(samples%3)*.15
		fire.sprite("flame_01",Vector3(0,.38,0),Vector2(.65,height),Color(1,.24,.025,.65),.48,Vector3.UP*.45,0,.35)
		fire.sprite("flame_01",Vector3(0,.22,0),Vector2(.22,.50),Color(1,.79,.24,.75),.27,Vector3.UP*.3,0,.3)
		fire.sprite("spotlight_1",Vector3.UP*.07,Vector2(.7,.7),Color(1,.32,.04,.35),.4,Vector3.ZERO,0,.5,true,true)
		if samples%2==0:
			fire.sprite("spark_05",Vector3.UP*.65,Vector2(.10,.22),Color(1,.7,.15,.9),.6,Vector3(sin(samples)*.35,1.3,cos(samples)*.35),0,.2)
		samples+=1
	if samples>=3 and ghost_count==1 or samples>=6 and ghost_count==2: afterimage()
	last_point=current

static func ember_sweep(parent: Node3D, point: Vector3) -> void:
	var fx=make(parent,point,.3)
	for i in 9:
		var a:=i*TAU/9
		var radial:=Vector3(cos(a),0,sin(a))
		fx.sprite("flame_01",radial*1.4+Vector3.UP*.55,Vector2(.55,.8),Color(1,.42,.06,.7),.28,radial*4.0,0,.35)
	fx.spray(Color("ffc967"),7,2.0,.3,"spark_05",.5)

static func ember_impact(parent: Node3D, point: Vector3) -> void:
	var fx=make(parent,point,1.15,"ember_landing")
	fx.light_pulse(Color("ff822d"),6.2,3.3,.55)
	# Separate the fast blast from the longer-lived smoke and embers.
	var wave=make(parent,point,.48,"ember_shockwave")
	wave.ground_pattern(3.0,Color("ff9b37"),0,.85)
	fx.sprite("spotlight_1",Vector3.UP*.18,Vector2(2.1,2.1),Color(1,.87,.45,.85),.14,Vector3.ZERO,0,1.5,true,true)
	for i in 12:
		var a:=float(i)*TAU/12.0;var ray:=Vector3(cos(a),0,sin(a))
		var size:=.85+float(i%3)*.16
		fx.sprite("flame_01",ray*.7+Vector3.UP*.35,Vector2(size,1.5+float(i%2)*.35),Color(1,.28,.025,.80),.46,ray*4.2+Vector3.UP*.35,float(i%3)*.012,.3)
		if i%2==0:
			fx.sprite("flame_01",ray*.75+Vector3.UP*.28,Vector2(.35,.7),Color(1,.75,.20,.75),.24,ray*4,0,.25)
		fx.sprite("spark_05",ray*.6+Vector3.UP*.5,Vector2(.09,.24),Color(1,.72,.25,.95),.8+float(i%3)*.1,ray*(1.6+float(i%3)*.4)+Vector3.UP*(1.3+float(i%2)*.5),.04,.15)
	for i in 4:
		var a:=float(i)*TAU/4.0;var ray:=Vector3(cos(a),0,sin(a))
		fx.sprite("smoke_01",ray*.75+Vector3.UP*.3,Vector2(1.2,.85),Color(.24,.18,.14,.28),.85,ray*.5+Vector3.UP*.6,.16,1.6,false)
	fx.sprite("scorch_01",Vector3.UP*.06,Vector2(2.7,2.7),Color(.14,.09,.05,.3),1.05,Vector3.ZERO,.07,1.15,false,true)

static func snare_cast(parent: Node3D, point: Vector3) -> void:
	var fx=make(parent,point,.75)
	# Corrupted-spawn language: a rune, a bright crystal heart, and lift-off motes.
	fx.sprite("effect_1",Vector3(0,.12,0),Vector2(1.8,1.8),Color(.72,.45,.95,.34),.62,Vector3.ZERO,0,1.0,true,true)
	# A real faceted cluster, offset from the caster to preserve the gnome silhouette.
	for i in 3:
		var center:=Vector3(.85+float(i)*.24,.35,-.65)
		fx.crystal(center,1.25 if i==1 else .8,.20,Color("dcafff"),.65,Vector3.UP*.4,float(i)*.025)
	for i in 7:
		var a:=float(i)*TAU/7.0;var radial:=Vector3(cos(a),0,sin(a))
		var shard=fx.crystal(radial*1.5+Vector3.UP*.22,.5,.12,Color("bc87e9"),.55,radial*.7+Vector3.UP*.5,float(i%3)*.035)
		shard.rotation=Vector3(sin(a)*.3,a,cos(a)*.3)
	fx.light_pulse(Color("b27fff"),5.7,2.4,.7,.035)
	for i in 7:
		var a:=float(i)*TAU/7;var ray:=Vector3(cos(a),0,sin(a))
		fx.arc(ray*.5+Vector3.UP*.13,ray*3.7+Vector3.UP*.13,Color("c08aff"),.45,float(i%3)*.035)
	fx.ground_pattern(5.0,Color("c287ec"),1)
	fx.spray(Color("c8a0ed"),12,3.4,.65,"spark_05",.7)

static func root_target(enemy: Node3D) -> void:
	if enemy.dead: return
	var existing=enemy.get_node_or_null("RootSnareVFX")
	if existing!=null:
		existing.age=0.0
		existing.samples=0
		existing.root_geometry.show()
		return
	var fx=make(enemy,enemy.global_position,4.3,"roots")
	fx.name="RootSnareVFX";fx.subject=enemy
	for i in 3:
		var a:=float(i)*TAU/3
		fx.arc(Vector3(cos(a)*.7,.15,sin(a)*.7),Vector3(-sin(a)*.35,1.4,cos(a)*.35),Color("c897ff"),.5,float(i)*.055)
	fx.root_geometry=Node3D.new();fx.add_child(fx.root_geometry)
	var radius: float=.95 if enemy.is_heart else .52
	for i in 5:
		var points: Array[Vector3]=[]
		for j in 9:
			var t:=float(j)/8
			var a:=i*TAU/5+t*2.7
			var r:=radius*(1.25-t*.55)+sin(t*9.0+float(i))*.04
			points.append(Vector3(cos(a)*r,.06+t*(1.1 if enemy.is_heart else .8),sin(a)*r))
		var root_mesh=fx.tube(fx.root_geometry,points,.10,Color("93613a"),true)
		var bark:=ShaderMaterial.new();bark.shader=preload("res://shaders/spore_root.gdshader")
		bark.set_shader_parameter("tint",Color("68482e"));bark.set_shader_parameter("height",1.2 if enemy.is_heart else .9)
		bark.set_shader_parameter("offset",float(i)*.035)
		root_mesh.material_override=bark;fx.root_materials.append(bark)
		for j in points.size(): points[j]+=Vector3.UP*.07
		var vein=fx.tube(fx.root_geometry,points,.018,Color("ad72cf"),true)
		var glow:=ShaderMaterial.new();glow.shader=preload("res://shaders/spore_root.gdshader")
		glow.set_shader_parameter("tint",Color("b784d3"));glow.set_shader_parameter("height",1.3 if enemy.is_heart else 1.0)
		glow.set_shader_parameter("offset",float(i)*.035)
		vein.material_override=glow;fx.root_materials.append(glow)
	fx.sprite("smoke_01",Vector3.UP*.28,Vector2(radius*2.5,.9),Color(.56,.21,.67,.45),.7,Vector3.UP*.35,0,1.7,false)
	fx.spray(Color("d6abf0"),8,radius,1.5,"spark_05",.5)

func tube(parent: Node3D, points: Array[Vector3], width: float, color: Color, bright: bool=false) -> MeshInstance3D:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3]=[]
	for i in points.size():
		var tangent: Vector3=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
		var side:=tangent.cross(Vector3.FORWARD).normalized()
		var up:=side.cross(tangent).normalized()
		for j in 6:
			var a:=j*TAU/6
			verts.append(points[i]+(side*cos(a)+up*sin(a))*width*(1.0-float(i)/points.size()*.8))
	for i in points.size()-1:
		for j in 6:
			var a:=i*6+j;var b:=i*6+(j+1)%6;var c:=a+6;var d:=b+6
			for index in [a,c,b,b,c,d]: st.add_vertex(verts[index])
	st.generate_normals()
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.9
	if bright: mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh

static func sanctuary(parent: Node3D, point: Vector3) -> void:
	var fx=make(parent,point,1.0,"sanctuary")
	fx.sprite("effect_1",Vector3.UP*.12,Vector2(2.4,2.4),Color(1,.83,.38,.24),.8,Vector3.ZERO,0,1.2,true,true)
	fx.light_pulse(Color("ffe1a2"),7.0,2.8,.9,.01)
	fx.ground_pattern(5.0,Color("ffdf83"),2,.65)
	# Soft textured shafts leave faces and the interior of the healing area readable.
	for i in 7:
		var a:=float(i)*TAU/7.0
		fx.sprite("spotlight_6",Vector3(cos(a)*2.3,1.15,sin(a)*2.3),Vector2(.55,2.5),Color(1,.84,.48,.24),.78,Vector3.UP*.6,float(i%3)*.04,.65)
	for i in 18:
		var a:=float(i)*2.39996;var r:=1.0+float(i%4)*.65
		fx.sprite("spark_05",Vector3(cos(a)*r,.15,sin(a)*r),Vector2(.10,.16),Color(1,.89,.57,.8),.75,Vector3.UP*(1.0+float(i%3)*.3),float(i%4)*.04,.35)

static func heal_ally(parent: Node3D, source: Vector3, ally: Node3D, large: bool=true) -> void:
	var pulse=make(parent,source+Vector3.UP*.75,.32,"heal_pulse")
	pulse.subject=ally;pulse.last_point=pulse.global_position
	pulse.add_to_group("healing_pulses")
	pulse.sprite("spotlight_1",Vector3.ZERO,Vector2(.55,.55),Color("ffe6a0"),.32,Vector3.ZERO,0,.6)
	var fx=make(ally,ally.global_position,.95 if large else .45,"heal_halo")
	fx.add_to_group("healing_halos")
	fx.ground_pattern(.85,Color("ffe6a0"),2,.65)
	fx.sprite("effect_1",Vector3.UP*.65,Vector2(.85,1.25),Color(1,.88,.52,.25),fx.duration,Vector3.UP*.4,0,1.1)
	if large:
		var points: Array[Vector3]=[]
		for i in 33:
			var a:=float(i)*TAU/32.0
			points.append(Vector3(cos(a)*.48,2.65,sin(a)*.48))
		var halo=fx.tube(fx,points,.035,Color("ffe6a0"),true)
		halo.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		fx.parts.append({"node":halo,"material":halo.material_override,"color":Color("ffe6a0"),"life":.8,"delay":.08,"velocity":Vector3.UP*.18,"growth":1.06,"origin":Vector3.ZERO})
		fx.sprite("light_02",Vector3.UP*2.65,Vector2(.9,.3),Color(1,.83,.45,.40),.7,Vector3.UP*.18,.08,1.1)
	fx.spray(Color("fff0b8"),6,.55,fx.duration,"spark_05",1.6)

func spore_motes() -> void:
	var fx=make(self,global_position,.85,"spore_motes")
	fx.add_to_group("spore_motes")
	for i in 3:
		var a:=age*3.0+float(i)*TAU/3.0
		var point:=Vector3(cos(a)*.8,.25,sin(a)*.8)
		fx.sprite("light_02",point,Vector2(.16,.16),Color(.8,.48,1,.65),.8,Vector3(cos(a)*.15,.55,sin(a)*.15),0,.35)

static func cloud(parent: Node3D, point: Vector3) -> Node3D:
	var fx=make(parent,point,3.0)
	fx.ground_pattern(2.8,Color("ac72c8"),3)
	for i in 9:
		var a:=i*2.399
		fx.sprite("smoke_01",Vector3(cos(a)*1.1,.17,sin(a)*1.1),Vector2(1.6,.7),Color(.51,.27,.59,.20),2.6,Vector3(0,.12,0),float(i%3)*.08,1.6,false)
	fx.spray(Color("d9adf0"),12,1.4,2.7,"spark_05",.28)
	return fx

static func projectile_trail(parent: Node3D, bolt: Node3D, color: Color, width: float=.16, leafy: bool=false) -> Node3D:
	var fx=make(parent,Vector3.ZERO,1.1,"trail")
	fx.subject=bolt;fx.trail_color=Color("55dc85") if leafy else color;fx.trail_width=width
	fx.nature_trail=leafy
	fx.trail_mesh=MeshInstance3D.new();fx.add_child(fx.trail_mesh)
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo=true;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	fx.trail_mesh.material_override=mat;fx.trail_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return fx

func update_trail() -> void:
	if is_instance_valid(subject) and not subject.is_queued_for_deletion():
		var p: Vector3=subject.global_position
		glint_clock+=get_process_delta_time()
		if glint_clock>=.08 and not nature_trail:
			glint_clock=0.0
			# Part delays are relative to this effect's birth, not the particle's birth.
			var local_point:=to_local(p)
			sprite("spark_05",local_point,Vector2(.22,.22),Color(trail_color,.85),.18,Vector3.UP*.18,age,.4)
			samples+=1
			if samples%2==0:
				var direction: Vector3=Vector3.FORWARD if trail_points.is_empty() else (p-trail_points.back()).normalized()
				var shard=crystal(local_point,.34,.085,trail_color.lerp(Color.WHITE,.6),.20,-direction*.65+Vector3.UP*.2,age)
				shard.rotation=Vector3(.45,float(samples),.5)
		if nature_trail and glint_clock>=.065 and samples<12:
			glint_clock=0.0;samples+=1
			var direction: Vector3=subject.direction
			var side:=direction.cross(Vector3.UP).normalized()
			var wake=make(get_parent(),p,.65,"ironbark_leaves")
			for i in 2:
				var sign_side:=1.0 if i==0 else -1.0
				wake.leaf(side*.10*sign_side, -direction*.65+side*.65*sign_side+Vector3.UP*.35, .52+float(i)*.08, samples+i)
		if trail_points.is_empty() or trail_points.back().distance_to(p)>.04: trail_points.append(p)
		if trail_points.size()>11: trail_points.pop_front()
	else:
		if not trail_points.is_empty(): trail_points.pop_front()
		if trail_points.size()<2: queue_free();return
	if trail_points.size()<2: return
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in trail_points.size()-1:
		var a: Vector3=trail_points[i];var b: Vector3=trail_points[i+1]
		var side: Vector3=(b-a).normalized().cross(Vector3.UP)*trail_width
		var t:=float(i+1)/trail_points.size()
		st.set_color(Color(trail_color,t*.85))
		for p in [a-side*t,b-side*t,a+side*t,a+side*t,b-side*t,b+side*t]:st.add_vertex(p)
		st.set_color(Color(trail_color.lerp(Color.WHITE,.75),t*.65))
		side*=.22
		for p in [a-side*t,b-side*t,a+side*t,a+side*t,b-side*t,b+side*t]:st.add_vertex(p+Vector3.UP*.004)
	trail_mesh.mesh=st.commit()

# Small folded leaves alternate dark green and lime for readable tumbling silhouettes.
func leaf(point: Vector3, velocity: Vector3, life: float, seed_value: int) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [Vector3(0,0,-.22),Vector3(-.12,0,0),Vector3(0,.045,.22),Vector3(0,0,-.22),Vector3(0,.045,.22),Vector3(.12,0,0)]:
		st.add_vertex(vertex)
	st.generate_normals()
	var node:=MeshInstance3D.new();node.mesh=st.commit()
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.albedo_color=Color("a8da60") if seed_value%2==0 else Color("389953")
	node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node);node.position=point;node.rotation=Vector3(.6,float(seed_value)*2.4,.4)
	node.add_to_group("ironbark_leaves")
	parts.append({"node":node,"material":mat,"color":mat.albedo_color,"life":life,"delay":0.0,"velocity":velocity,"growth":.65,"origin":point,"rotation":node.rotation,"spin":Vector3(2.4,3.5,1.2),"gravity":Vector3.DOWN*.8})

static func splinter_impact(parent: Node3D, point: Vector3, direction: Vector3) -> void:
	var fx=make(parent,point,.65,"ironbark_impact")
	fx.add_to_group("ironbark_impacts")
	fx.sprite("spotlight_1",Vector3.ZERO,Vector2(.65,.65),Color(.82,1,.55,.9),.12,Vector3.ZERO,0,.3)
	var side:=direction.cross(Vector3.UP).normalized()
	for i in 9:
		var a:=float(i)*2.39996
		var velocity:=direction*(.5+float(i%3)*.6)+side*cos(a)*2.8+Vector3.UP*(sin(a)*1.7+.7)
		var node:=MeshInstance3D.new();var shape:=CylinderMesh.new()
		shape.top_radius=.008;shape.bottom_radius=.035+float(i%2)*.012
		shape.height=.22+float(i%3)*.10;shape.radial_segments=4;shape.rings=1;node.mesh=shape
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color=Color("d6b77c") if i%3 else Color("8a5a31")
		node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx.add_child(node);node.quaternion=Quaternion(Vector3.UP,velocity.normalized())
		node.add_to_group("ironbark_splinters")
		fx.parts.append({"node":node,"material":mat,"color":mat.albedo_color,"life":.45+float(i%3)*.06,"delay":0.0,"velocity":velocity,"growth":.5,"origin":Vector3.ZERO,"rotation":node.rotation,"spin":Vector3(3,1,2),"gravity":Vector3.DOWN*4.0})
	for i in 3: fx.leaf(Vector3.ZERO,side*(float(i)-1)*1.5+Vector3.UP*.8,.6,i)

static func impact(parent: Node3D, point: Vector3, color: Color, nature: bool=true) -> void:
	var fx=make(parent,point,.38)
	for i in 5:
		var a:=float(i)*TAU/5;var ray:=Vector3(cos(a),sin(a),.15)
		fx.stroke(Vector3.UP*.7+ray*.12,Vector3.UP*.7+ray*.65,color,.021,.25)
	fx.sprite("spotlight_1",Vector3.UP*.6,Vector2(.8,.8),Color("fff4ce"),.15,Vector3.ZERO,0,.25)
	fx.spray(color,7,.7,.38,"trace_01" if nature else "spark_05",1.1)

func _process(delta: float) -> void:
	age+=delta
	if is_instance_valid(encounter_owner) and encounter_owner.state!=encounter_owner.State.COMBAT:
		queue_free();return
	for track in light_tracks:
		var t: float=(age-track.delay)/track.life
		track.node.light_energy=track.peak*light_envelope(t)
		track.node.light_color=track.color.lerp(Color("fff5e4"),.55*(1.0-smoothstep(.12,.35,t)))
	if mode=="dash":
		sample_clock+=delta
		if sample_clock>=.025: sample_clock=0.0;dash_sample()
	elif mode=="trail": update_trail()
	elif mode=="heal_pulse":
		if not is_instance_valid(subject): queue_free();return
		var travel:=minf(1.0,age/.23)
		global_position=last_point.lerp(subject.global_position+Vector3.UP*.85,travel)+Vector3.UP*sin(travel*PI)*.45
	elif mode=="roots":
		if not is_instance_valid(subject) or subject.dead: queue_free();return
		# Status is authoritative, including refreshed casts and early removals.
		if subject.root_time<=0:
			root_geometry.hide()
			if subject.slow_time<=0: queue_free();return
		elif age>=duration-.3: duration=age+.4
		root_geometry.scale.y=lerpf(.65,1.0,clampf(age/.35,0.0,1.0))*clampf(subject.root_time/.22,.01,1.0)
		for mat in root_materials: mat.set_shader_parameter("growth",clampf(age/.4,0.0,1.0))
		sample_clock+=delta
		if subject.root_time>0 and sample_clock>=.28:
			sample_clock=0.0;spore_motes()
		if subject.root_time<=0 and samples==0:
			samples=1
			spray(Color(.54,.37,.66,.4),4,.4,maxf(.1,subject.slow_time),"spark_05",.2)
			for i in range(parts.size()-4,parts.size()): parts[i].delay+=age
	for mat in grounds: mat.set_shader_parameter("progress",clampf(age/duration,0,1))
	for item in parts:
		var node: Node3D=item.node
		var local_age: float=age-item.delay
		node.visible=local_age>=0 and local_age<item.life
		if not node.visible: continue
		var t: float=local_age/item.life
		var fade: float=minf(1.0,local_age/.035)*(1.0-t)*(1.0-t)
		node.position=item.origin+item.velocity*local_age+item.get("gravity",Vector3.ZERO)*local_age*local_age*.5
		if item.has("spin"): node.rotation=item.rotation+item.spin*local_age
		node.scale=item.get("base_scale",Vector3.ONE)*lerpf(1.0,item.growth,t)
		var tint: Color=item.color;tint.a*=fade
		if node is Sprite3D: node.modulate=tint
		elif item.material is ShaderMaterial:
			item.material.set_shader_parameter("tint",tint)
			if item.get("flame",false): item.material.set_shader_parameter("progress",t)
		else: item.material.albedo_color=tint
	if age>=duration: queue_free()
