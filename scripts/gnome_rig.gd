extends Node3D
## Existing shared skin, real Mixamo locomotion and two-handed magic capture.
const IDS := ["ember_hollow", "ironbark", "spore_grove", "light_realm", "universal"]
const LOWER_BODY := ["root", "pelvis", "thigh.L", "shin.L", "foot.L", "toe.L",
	"thigh.R", "shin.R", "foot.R", "toe.R"]
const MODEL_SCALE := 2.4
const WALK_STRIDE := .421814
const RUN_STRIDE := .480052
const BLEND_SECONDS := .14
var actor: CharacterBody3D
var model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var weapon: Node3D
var hand_socket: BoneAttachment3D
var back_socket: BoneAttachment3D
var grip_transform := Transform3D.IDENTITY
var stow_transform := Transform3D.IDENTITY
var grip_rotations: Dictionary = {}
var current_class := -1
var current_clip := ""
var clip_time := 0.0
var travel_phase := 0.0
var prior_health := 100.0
var prior_power := 0.0
var action_remaining := 0.0
var attack_anticipation := .18
var marker: Label3D
var player_tag := ""
var sprites: Array[Sprite3D] = [] # Legacy VFX compatibility; 3D dash uses its flame wake.
var transition_from: Array[Transform3D] = []
var transition_time := BLEND_SECONDS

func find_type(node: Node, kind: String) -> Node:
	if node.is_class(kind): return node
	for child in node.get_children():
		var found := find_type(child, kind)
		if found != null: return found
	return null

func _ready() -> void:
	actor = get_parent()
	for child in actor.get_children():
		if child is Label3D: marker = child; player_tag = child.text
	set_class(actor.class_id)

func set_class(id: int) -> void:
	current_class = id
	if is_instance_valid(model): remove_child(model); model.queue_free()
	model = load("res://assets/characters/gnomes/rigged/%s.glb" % IDS[id]).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * MODEL_SCALE
	skeleton = find_type(model,"Skeleton3D")
	animation_player = find_type(model,"AnimationPlayer")
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in ["Idle", "Walk", "Run"]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var socket := BoneAttachment3D.new()
	socket.bone_name = "hand.R"
	skeleton.add_child(socket)
	hand_socket = socket
	back_socket = BoneAttachment3D.new()
	back_socket.bone_name = "chest"
	skeleton.add_child(back_socket)
	fit_grip()
	weapon = load("res://scripts/gnome_weapon.gd").new()
	socket.add_child(weapon)
	weapon.configure(id)
	weapon.transform = grip_transform
	weapon.visible = id < 4
	current_clip = ""
	transition_from.clear()
	travel_phase = 0.0
	play_clip("Idle")

func play_clip(clip: String) -> void:
	if current_clip == clip: return
	transition_from.clear()
	if not current_clip.is_empty():
		for i in skeleton.get_bone_count():
			transition_from.append(skeleton.get_bone_pose(i))
	transition_time = 0.0
	current_clip = clip
	clip_time = 0.0
	animation_player.play(clip, 0)
	animation_player.seek(0, true)

func sample_clip(clip: String, time: float) -> void:
	if animation_player.current_animation != clip: animation_player.play(clip, 0)
	animation_player.seek(time, true)

func fit_grip() -> void:
	var hand := skeleton.get_bone_global_rest(skeleton.find_bone("hand.R"))
	var index := skeleton.get_bone_global_rest(skeleton.find_bone("index.01.R")).origin
	var pinky := skeleton.get_bone_global_rest(skeleton.find_bone("pinky.01.R")).origin
	var middle := skeleton.get_bone_global_rest(skeleton.find_bone("middle.01.R")).origin
	var across := (index-pinky).normalized()
	var forward := (middle-hand.origin).normalized()
	var normal := across.cross(forward).normalized()
	var shaft := across
	var x := shaft.cross(normal).normalized()
	var center := hand.origin.lerp((index+pinky)*.5,.72) + normal*.017
	var palm := Transform3D(Basis(x,shaft,x.cross(shaft)).scaled(Vector3.ONE*.38),center)
	grip_transform = hand.affine_inverse()*palm
	var chest := skeleton.get_bone_global_rest(skeleton.find_bone("chest"))
	var back := Transform3D(Basis(Vector3.FORWARD,.35).scaled(Vector3.ONE*.38),Vector3(.04,.47,-.16))
	stow_transform = chest.affine_inverse()*back
	grip_rotations.clear()
	for digit in ["index","middle","ring","pinky"]:
		for joint in 3:
			var bone := skeleton.find_bone("%s.%02d.R" % [digit,joint+1])
			var rest := skeleton.get_bone_global_rest(bone)
			var direction := rest.basis.y.normalized()
			var axis := direction.cross(normal).normalized()
			var local_axis := rest.basis.inverse()*axis
			grip_rotations[bone] = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion(local_axis.normalized(),deg_to_rad([38.0,65.0,35.0][joint]))
	for joint in 2:
		var bone := skeleton.find_bone("thumb.%02d.R" % (joint+1))
		var rest := skeleton.get_bone_global_rest(bone)
		var target := (center-rest.origin).normalized()
		var axis := rest.basis.y.normalized().cross(target).normalized()
		grip_rotations[bone] = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion((rest.basis.inverse()*axis).normalized(),deg_to_rad(35.0 if joint==0 else 45.0))

func update_equipment(casting: bool) -> void:
	if current_class == 4: return
	var socket := back_socket if casting else hand_socket
	if weapon.get_parent() != socket:
		weapon.reparent(socket,false)
	weapon.transform = stow_transform if casting else grip_transform
	if not casting:
		for bone in grip_rotations:
			skeleton.set_bone_pose_rotation(bone, grip_rotations[bone])

func _process(delta: float) -> void:
	if current_class != actor.class_id: set_class(actor.class_id)
	clip_time += delta
	action_remaining = maxf(0, action_remaining-delta)
	var speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var locomotion := "Run" if speed > 1.8 else "Walk"
	var stride := RUN_STRIDE if locomotion == "Run" else WALK_STRIDE
	travel_phase = fmod(travel_phase + speed * delta / (stride * MODEL_SCALE), 1.0)
	if actor.downed:
		play_clip("Down")
		action_remaining = 0.0
	elif actor.health < prior_health:
		play_clip("Hit"); action_remaining = .4
	elif actor.cast_elapsed>=0.0:
		play_clip("Cast")
		clip_time=actor.cast_elapsed
		action_remaining=maxf(0.0,actor.CAST_DURATION-actor.cast_elapsed)
	elif actor.power_cooldown > prior_power + .1:
		play_clip("Cast")
		action_remaining = animation_player.get_animation("Cast").length
	elif actor.pending_attack and current_clip != "Attack":
		play_clip("Attack")
		attack_anticipation = maxf(.01,actor.attack_windup)
		action_remaining = attack_anticipation+.22
	elif action_remaining <= 0:
		play_clip(locomotion if speed > .2 else "Idle")
	prior_health = actor.health
	prior_power = actor.power_cooldown
	if not actor.downed:
		var aim: Vector2=actor.power_aim() if actor.cast_elapsed>=0.0 else actor.last_input
		var direction := Vector3(aim.x+aim.y,0,aim.y-aim.x)
		if direction.length_squared()>.01: rotation.y = atan2(direction.x,direction.z)
	var animation := animation_player.get_animation(current_clip)
	var sample := clip_time
	if current_clip in ["Walk", "Run"]:
		sample = travel_phase * animation.length
	elif current_clip == "Attack":
		sample = animation.length * (.6 * sample / attack_anticipation if sample <= attack_anticipation else .6 + .4 * (sample-attack_anticipation)/.22)
	if current_clip in ["Idle","Walk","Run"]: sample = fmod(sample, animation.length)
	else: sample = minf(sample, animation.length)
	# A moving caster keeps locomotion on the hips/legs, with the captured cast above.
	var lower_pose: Dictionary = {}
	if current_clip == "Cast" and speed > .2:
		sample_clip(locomotion, travel_phase * animation_player.get_animation(locomotion).length)
		for name in LOWER_BODY:
			var bone := skeleton.find_bone(name)
			if bone >= 0: lower_pose[bone] = skeleton.get_bone_pose(bone)
	sample_clip(current_clip, sample)
	for bone in lower_pose: skeleton.set_bone_pose(bone, lower_pose[bone])
	update_equipment(current_clip == "Cast")
	transition_time += delta
	if transition_from.size() == skeleton.get_bone_count() and transition_time < BLEND_SECONDS:
		var weight := smoothstep(0.0, 1.0, transition_time / BLEND_SECONDS)
		for i in skeleton.get_bone_count():
			skeleton.set_bone_pose(i, transition_from[i].interpolate_with(skeleton.get_bone_pose(i), weight))
	if current_class == 1: weapon.set_draw(actor.pending_attack)
	if marker != null:
		var tag := player_tag
		if actor.team_id>=0: tag="P%d%s" % [actor.team_id+1," ▼" if actor.controlled else " +"]
		marker.text=tag+" • DOWN\nHold E / U" if actor.downed else tag
		marker.position.y=1.1 if actor.downed else 3.0
		marker.no_depth_test=actor.downed




func hand_world(side: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand."+side)).origin

func cast_origin() -> Vector3:
	return (hand_world("L")+hand_world("R"))*.5
