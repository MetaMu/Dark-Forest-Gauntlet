extends Node3D
## Blender-exported equipment attached to the existing stepped pose rig.
var kind := -1
var bow_string: Node3D
var arrow: Node3D
var artwork: Node3D
var last_draw := -1
const Art=preload("res://scripts/forest_art.gd")

func cord(parent: Node3D,a: Vector3,b: Vector3,width: float,color: Color) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new();mesh.top_radius=width;mesh.bottom_radius=width
	mesh.height=a.distance_to(b);mesh.radial_segments=8
	node.mesh=mesh;node.position=(a+b)*.5
	var material:=StandardMaterial3D.new();material.albedo_color=color
	node.material_override=material
	parent.add_child(node)
	var direction: Vector3=(b-a).normalized()
	var side:=direction.cross(Vector3.FORWARD).normalized()
	node.basis=Basis(side,direction,side.cross(direction)).orthonormalized()

func configure(id: int) -> void:
	if id==kind: return
	kind=id;last_draw=-1
	if is_instance_valid(artwork):
		remove_child(artwork);artwork.queue_free()
	artwork=Node3D.new();add_child(artwork)
	bow_string=null;arrow=null
	match kind:
		0:
			var axe=Art.model(artwork,Art.PROPS+"axe_bronze.glb",Vector3(0,-.28,0),1.35)
			axe.rotation.y=.35
		1:
			Art.ruin(artwork,"ironbark_bow",Vector3.ZERO)
			bow_string=Node3D.new();artwork.add_child(bow_string)
			arrow=Node3D.new();artwork.add_child(arrow)
			cord(arrow,Vector3(-.3,0,.03),Vector3(.8,0,.03),.016,Color("d7ba83"))
			set_draw(false)
		2: Art.ruin(artwork,"spore_staff",Vector3.ZERO)
		3: Art.ruin(artwork,"light_staff",Vector3.ZERO)

func set_draw(drawing: bool) -> void:
	if not is_instance_valid(bow_string) or last_draw==int(drawing): return
	last_draw=int(drawing)
	for child in bow_string.get_children():
		bow_string.remove_child(child);child.queue_free()
	var pull:=Vector3(-.25 if drawing else .03,0,.02)
	cord(bow_string,Vector3(.03,.68,.02),pull,.009,Color("dccfac"))
	cord(bow_string,pull,Vector3(.03,-.68,.02),.009,Color("dccfac"))
	arrow.position.x=-.18 if drawing else 0.0

func pose(windup: bool,releasing: bool,left: bool,down: bool,back: bool) -> void:
	var sign_x: float=-1.0 if left else 1.0
	position=Vector3(sign_x*0.77,0.80, -0.03 if back else 0.04)
	scale=Vector3(sign_x,1,1)
	if down:
		position=Vector3(sign_x*0.8,0.12,0.06)
		rotation.z=sign_x*1.4
		return
	match kind:
		0: rotation.z=sign_x*(0.9 if windup else (-1.25 if releasing else -0.3))
		1:
			rotation.z=0
			position.x+=sign_x*(-0.12 if windup else (0.08 if releasing else 0.0))
			set_draw(windup)
			arrow.visible=not releasing
		2,3:
			rotation.z=sign_x*(0.18 if windup else (-0.35 if releasing else -0.08))
			position.y+=0.12 if windup else 0.0

