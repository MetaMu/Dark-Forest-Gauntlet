extends Node3D
## Cut-paper sprite animation: discrete 10 Hz poses; simulation stays at 60 Hz.
const IDS := ["ember_hollow", "ironbark", "spore_grove", "light_realm", "universal"]
var actor: CharacterBody3D
var sprites: Array[Sprite3D] = []
var atlases: Array[AtlasTexture] = []
var clock := 0.0
var last_tick := -1
var view := 3
var facing_left := false
var sheet: Texture2D
var current_class := -1
var body_pose: Node3D
var weapon: Node3D
var fall_step := 0
var marker: Label3D
var player_tag := ""

func _ready() -> void:
	actor = get_parent()
	for child in actor.get_children():
		if child is Label3D:
			marker=child
			player_tag=child.text
	body_pose=Node3D.new()
	body_pose.name="BodyPose"
	add_child(body_pose)
	for i in 3:
		var sprite := Sprite3D.new()
		var atlas := AtlasTexture.new()
		sprite.texture = atlas
		sprite.pixel_size = 2.4 / 416.0
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.shaded = false
		body_pose.add_child(sprite)
		sprites.append(sprite)
		atlases.append(atlas)
	weapon=load("res://scripts/gnome_weapon.gd").new()
	weapon.name="Weapon"
	add_child(weapon)
	set_class(actor.class_id)

func set_class(id: int) -> void:
	current_class = id
	weapon.configure(id)
	weapon.visible=id<4
	sheet = load("res://assets/characters/gnomes/v1/gnome_%s_apose_sheet.png" % IDS[id])
	for atlas in atlases:
		atlas.atlas = sheet
	update_regions()

func update_regions() -> void:
	# Split along the boot tops. Overlap by 6 px conceals the paper joints.
	atlases[0].region = Rect2(view * 512, 0, 512, 397)
	atlases[1].region = Rect2(view * 512, 391, 256, 121)
	atlases[2].region = Rect2(view * 512 + 256, 391, 256, 121)

func _process(delta: float) -> void:
	var camera:=get_viewport().get_camera_3d()
	if camera!=null:
		global_basis=camera.global_basis.orthonormalized()
	clock += delta
	var tick := int(clock * 10.0)
	if tick == last_tick:
		return
	last_tick = tick
	if current_class != actor.class_id:
		set_class(actor.class_id)
	var input: Vector2 = actor.last_input
	var walking: bool = Vector2(actor.velocity.x, actor.velocity.z).length() > 0.2 and not actor.downed
	if walking or actor.pending_attack or actor.attack_flash>0.0:
		facing_left = input.x < -0.1
		view = 2 if input.y < -0.35 else (0 if input.y > 0.35 and absf(input.x) < 0.3 else 3)
		update_regions()
	var cycle := tick % 6
	var stride := sin(float(cycle) / 6.0 * TAU) if walking else 0.0
	var bob := absf(stride) * 5.0 if walking else (2.0 if tick % 20 < 10 else 0.0)
	var thrust := 0.0
	if actor.attack_windup > 0.0:
		thrust = -7.0
	elif actor.attack_flash > 0.0:
		thrust = 11.0
	sprites[0].offset = Vector2(thrust, 464.0 - 198.5 + bob)
	sprites[1].offset = Vector2(-128, 12.5 + maxf(0,stride) * 13.0)
	sprites[2].offset = Vector2(128, 12.5 + maxf(0,-stride) * 13.0)
	# Reverse the two boot regions as well as the upper body for left travel.
	for i in 3:
		sprites[i].flip_h = facing_left
		if facing_left:
			sprites[i].offset.x *= -1.0
		var tint := Color("d7dfe0")
		if actor.downed:
			tint = Color("a6a0b1")
		elif actor.invulnerability > 0.0 and tick % 2 == 0:
			tint = Color("ffc1ac")
		sprites[i].modulate = tint
	fall_step=mini(3,fall_step+1) if actor.downed else maxi(0,fall_step-1)
	var fall: float=fall_step/3.0
	body_pose.rotation.z=fall*PI*0.5
	# The sideways silhouette is about two units wide. Lift its center by half
	# that width so the ground plane cannot clip the fallen face and shoulders.
	body_pose.position=Vector3(fall*1.0,fall*1.03,0)
	weapon.pose(actor.pending_attack,actor.attack_flash>0.0,facing_left,actor.downed,view==2)
	if marker!=null:
		var tag: String=player_tag
		var revive_keys: String="E / A"
		if actor.team_id>=0:
			tag="P%d%s" % [actor.team_id+1," ▼" if actor.controlled else " +"]
			revive_keys="%s / %s" % [actor.LocalInput.key_label(-1,"revive"),actor.LocalInput.key_label(-2,"revive")]
		marker.text=tag+" • DOWN\nHold "+revive_keys if actor.downed else tag
		marker.position.y=2.7 if actor.downed else 3.8
		marker.font_size=28 if actor.downed else (34 if actor.team_id>=0 and not actor.controlled else 48)
		marker.outline_size=4
		marker.no_depth_test=actor.downed
	if walking and cycle in [0,3] and actor.has_method("footstep"):
		actor.footstep()
