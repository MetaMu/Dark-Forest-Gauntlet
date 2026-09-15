extends Node3D
## Short-lived, depth-tested effects. No particles or nodes survive their lifetime.
var lifetime := 0.4
var elapsed := 0.0
var start_scale := Vector3.ONE
var rise := 0.0
var expansion := 0.8

func _process(delta: float) -> void:
	elapsed += delta
	var progress := minf(1.0, elapsed / lifetime)
	scale = start_scale * (1.0 + progress * expansion)
	position.y += rise * delta
	for child in get_children():
		if child is MeshInstance3D:
			child.transparency = progress
			if child.has_meta("velocity"):
				child.position+=child.get_meta("velocity")*delta
		elif child is Label3D:
			child.modulate.a = 1.0 - progress
	if elapsed >= lifetime:
		queue_free()

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

static func ring(parent: Node3D, point: Vector3, color: Color, radius: float, duration: float = 0.4) -> Node3D:
	var fx = load("res://scripts/combat_fx.gd").new()
	fx.lifetime = duration
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.9
	torus.outer_radius = radius
	torus.rings = 24
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.material_override = material(color)
	fx.add_child(mesh)
	parent.add_child(fx)
	fx.global_position = point + Vector3.UP * 0.12
	return fx

static func number(parent: Node3D, point: Vector3, value: String, color: Color) -> void:
	var fx = load("res://scripts/combat_fx.gd").new()
	fx.lifetime = 0.7
	fx.rise = 1.4
	var label := Label3D.new()
	label.text = value
	label.font_size = 48
	label.pixel_size = 0.009
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	fx.add_child(label)
	parent.add_child(fx)
	fx.global_position = point + Vector3.UP * 1.8

static func burst(parent: Node3D,point: Vector3,color: Color,size: float = 1.0) -> void:
	var fx=load("res://scripts/combat_fx.gd").new()
	fx.lifetime=0.28
	fx.expansion=0.0
	for i in 8:
		var spark:=MeshInstance3D.new()
		var shape:=SphereMesh.new()
		shape.radius=0.08*size
		shape.height=0.25*size
		shape.radial_segments=4
		shape.rings=1
		spark.mesh=shape
		spark.material_override=material(color)
		var direction:=Vector3(cos(i*TAU/8),0.5+float(i%3)*0.2,sin(i*TAU/8))
		spark.set_meta("velocity",direction*4.0*size)
		fx.add_child(spark)
	parent.add_child(fx)
	fx.global_position=point
