extends Node3D
const Player=preload("res://scripts/player.gd")
const Rig=preload("res://scripts/gnome_rig.gd")
var actors: Array=[]
var elapsed:=0.0
var stage:=-1
var caption: Label
func _ready() -> void:
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("17262c");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c2d9df");env.ambient_light_energy=.65;world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=.85;sun.shadow_enabled=true;add_child(sun)
	var camera:=Camera3D.new();camera.position=Vector3(0,5,13);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=8;add_child(camera);camera.look_at(Vector3(0,1,0));camera.current=true
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,20);ground.mesh=plane;var mat:=StandardMaterial3D.new();mat.albedo_color=Color("243e3b");ground.material_override=mat;add_child(ground)
	for i in 5:
		var actor=Player.new();actor.class_id=[4,0,1,2,3][i];actor.position.x=(i-2)*2.7;add_child(actor);actor.set_physics_process(false);actor.last_input=Vector2(-1,1)
		var marker:=Label3D.new();marker.text=["UNIVERSAL","EMBER HOLLOW","IRONBARK","SPORE GROVE","LIGHT REALM"][i];marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.font_size=28;marker.pixel_size=.007;actor.add_child(marker)
		var rig=Rig.new();rig.name="GnomePuppet";actor.add_child(rig);actors.append(actor)
	var canvas:=CanvasLayer.new();add_child(canvas);caption=Label.new();caption.position=Vector2(30,28);caption.add_theme_font_size_override("font_size",26);canvas.add_child(caption)
func _process(delta: float) -> void:
	elapsed+=delta
	var next:=int(elapsed/2.0)%6
	if next!=stage:
		stage=next
		caption.text="GNOME BATTLE RIGS  ·  "+["IDLE","WALK","ATTACK","CAST","HIT","DOWN / REVIVE"][stage]
		for actor in actors:
			var rig=actor.get_node("GnomePuppet")
			actor.downed=false;actor.velocity=Vector3.ZERO;actor.pending_attack=false;actor.power_cooldown=0
			match stage:
				1: actor.velocity=Vector3(1,0,0)
				2: rig.play_clip("Attack");rig.action_remaining=1.9
				3: rig.play_clip("Cast");rig.action_remaining=1.9
				4: actor.health-=1
				5: actor.downed=true
