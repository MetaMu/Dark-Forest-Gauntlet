extends Node3D
## Warning is locked to the floor. Rooting/staggering the caster cancels it.
var encounter: Node3D
var caster: CharacterBody3D
var age:=0.0
var warning_time:=1.2
var pool_time:=2.7
var radius:=2.2
var active:=false
var cancelled:=false
var next_tick:=0.0
var disk: MeshInstance3D
var rim: MeshInstance3D
var pod: MeshInstance3D
var label: Label3D
var mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemy_hazards")
	mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(1,.48,.12,.17)
	disk=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
	cylinder.top_radius=radius;cylinder.bottom_radius=radius;cylinder.height=.025;cylinder.radial_segments=40
	disk.mesh=cylinder;disk.material_override=mat;disk.position.y=.09;add_child(disk)
	rim=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=radius-.06;ring.outer_radius=radius
	rim.mesh=ring;rim.position.y=.12;rim.material_override=load("res://scripts/combat_fx.gd").material(Color("ffc56e"));add_child(rim)
	pod=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=.3;ball.height=.6
	pod.mesh=ball;pod.material_override=load("res://scripts/combat_fx.gd").material(Color("d0ef54"));add_child(pod)
	label=Label3D.new();label.text="MOVE!";label.position.y=.5;label.font_size=30;label.pixel_size=.01
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("ffe2a0");add_child(label)

func _physics_process(delta: float) -> void:
	if encounter.state!=encounter.State.COMBAT: queue_free();return
	if not active and (not is_instance_valid(caster) or caster.dead or caster.root_time>0 or caster.stagger>0):
		cancelled=true;queue_free();return
	age+=delta
	if not active:
		pod.position.y=lerpf(4.5,.2,clampf((age-.7)/.5,0,1))
		rim.scale=Vector3.ONE*(.96+.04*sin(age*12))
		if age>=warning_time:
			active=true;pod.hide();label.text="SPORE POOL"
			mat.albedo_color=Color(.48,.82,.16,.35)
			rim.material_override.albedo_color=Color("b3e44b")
			for player in encounter.room.players:
				if contains(player): player.take_damage(22)
			next_tick=age+.65
	else:
		if age>=next_tick:
			next_tick=age+.65
			for player in encounter.room.players:
				if contains(player): player.take_damage(6)
		var fade:=1.0-clampf((age-warning_time)/pool_time,0,1)
		mat.albedo_color.a=.1+.25*fade
		if age>=warning_time+pool_time: queue_free()

func contains(player: CharacterBody3D) -> bool:
	if player.downed: return false
	var flat:=Vector2(player.global_position.x-global_position.x,player.global_position.z-global_position.z)
	return flat.length()<=radius and encounter.visible_to(global_position,player.global_position)
