extends Node3D
## Shared 52-bone realm rig; pose sampling retains the handmade 12 fps cadence.
const IDS := ["ember_hollow", "ironbark", "spore_grove", "light_realm", "universal"]
var actor: CharacterBody3D
var model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var weapon: Node3D
var current_class := -1
var current_clip := ""
var clip_time := 0.0
var clock := 0.0
var last_tick := -1
var prior_health := 100.0
var prior_power := 0.0
var action_remaining := 0.0
var attack_anticipation := .18
var marker: Label3D
var player_tag := ""
var sprites: Array[Sprite3D] = [] # Legacy VFX compatibility; 3D dash uses its flame wake.

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
	model.scale = Vector3.ONE * 2.4
	skeleton = find_type(model,"Skeleton3D")
	animation_player = find_type(model,"AnimationPlayer")
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in ["Idle", "Walk"]: animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var socket := BoneAttachment3D.new()
	socket.bone_name = "hand.R"
	skeleton.add_child(socket)
	weapon = load("res://scripts/gnome_weapon.gd").new()
	socket.add_child(weapon)
	weapon.configure(id)
	weapon.scale = Vector3.ONE * .38
	weapon.visible = id < 4
	current_clip = ""
	play_clip("Idle")

func play_clip(clip: String) -> void:
	if current_clip == clip: return
	current_clip = clip; clip_time = 0.0
	animation_player.play(clip)
	animation_player.seek(0,true)

func _process(delta: float) -> void:
	if current_class != actor.class_id: set_class(actor.class_id)
	clock += delta; clip_time += delta; action_remaining = maxf(0,action_remaining-delta)
	if actor.downed:
		play_clip("Down")
	elif actor.health < prior_health:
		play_clip("Hit"); action_remaining = .4
	elif actor.power_cooldown > prior_power + .1:
		play_clip("Cast"); action_remaining = .8
	elif actor.pending_attack and current_clip != "Attack":
		play_clip("Attack"); attack_anticipation = maxf(.01,actor.attack_windup); action_remaining = attack_anticipation+.22
	elif action_remaining <= 0:
		play_clip("Walk" if Vector2(actor.velocity.x,actor.velocity.z).length() > .2 else "Idle")
	prior_health = actor.health; prior_power = actor.power_cooldown
	if not actor.downed:
		var direction := Vector3(actor.last_input.x+actor.last_input.y,0,actor.last_input.y-actor.last_input.x)
		if direction.length_squared()>.01: rotation.y = atan2(direction.x,direction.z)
	var tick := int(clock*12)
	if tick != last_tick:
		last_tick=tick
		var animation := animation_player.get_animation(current_clip)
		var sample := floorf(clip_time*12)/12.0
		if current_clip == "Attack":
			sample = animation.length * (.6 * sample / attack_anticipation if sample <= attack_anticipation else .6 + .4 * (sample-attack_anticipation)/.22)
		if current_clip in ["Idle","Walk"]: sample=fmod(sample,animation.length)
		else: sample=minf(sample,animation.length)
		animation_player.seek(sample,true)
	if current_class == 1: weapon.set_draw(actor.pending_attack)
	if marker != null:
		var tag := player_tag
		if actor.team_id>=0: tag="P%d%s" % [actor.team_id+1," ▼" if actor.controlled else " +"]
		marker.text=tag+" • DOWN\nHold E / U" if actor.downed else tag
		marker.position.y=1.1 if actor.downed else 3.0
		marker.no_depth_test=actor.downed
