extends Node3D
## Hand-attached anticipation driven by the same physics clock as the spell.
const COLORS := [Color("ff792b"),Color("9cdb59"),Color("c56fff"),Color("ffe695")]
var mode := "cast_charge"
var actor: CharacterBody3D
var rig: Node3D
var hands: Array[MeshInstance3D] = []
var lamp: OmniLight3D
var serial := 0
func _ready() -> void:
	actor=get_parent()
	rig=actor.get_node_or_null("GnomePuppet")
	serial=actor.cast_serial
	add_to_group("realm_vfx");add_to_group("cast_charges")
	for side in 2:
		var orb:=MeshInstance3D.new()
		var ball:=SphereMesh.new();ball.radius=.09;ball.height=.18;ball.radial_segments=12;ball.rings=6;orb.mesh=ball
		var mat:=StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color=Color(COLORS[actor.cast_class],.65)
		mat.emission_enabled=true;mat.emission=COLORS[actor.cast_class];mat.emission_energy_multiplier=1.5
		orb.material_override=mat;orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(orb);hands.append(orb)
	if get_tree().get_nodes_in_group("power_lights").size()<6:
		lamp=OmniLight3D.new();lamp.light_color=COLORS[actor.cast_class];lamp.omni_range=3.0
		lamp.shadow_enabled=false;lamp.light_energy=0;add_child(lamp);lamp.add_to_group("power_lights")
	_process(0)
func dispose() -> void:
	if is_instance_valid(lamp): lamp.remove_from_group("power_lights");lamp.light_energy=0
	remove_from_group("cast_charges");remove_from_group("realm_vfx")
	hide();queue_free()
func _process(_delta: float) -> void:
	if not is_instance_valid(actor) or not actor.pending_power or actor.downed or not actor.combat_enabled or actor.cast_serial!=serial:
		dispose();return
	var progress:=clampf(actor.cast_elapsed/actor.CAST_RELEASE,0,1)
	for i in 2:
		hands[i].global_position=rig.hand_world("L" if i==0 else "R") if is_instance_valid(rig) and rig.has_method("hand_world") else actor.global_position+Vector3.UP
		hands[i].scale=Vector3.ONE*(.25+progress*1.25)*(1.0+.08*sin(progress*TAU*3))
	if is_instance_valid(lamp):
		lamp.global_position=(hands[0].global_position+hands[1].global_position)*.5
		lamp.light_energy=progress*progress*1.8
