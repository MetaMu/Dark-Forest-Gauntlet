extends Node3D
## Blender-authored bark creatures retain the existing 8 Hz animation cues.
var enemy: CharacterBody3D
var body: Node3D
var time := 0.0
var tick := -1
var combat_player: AnimationPlayer
var combat_mode := false
var current_clip := ""
var visual_hold := 0.0
func _ready() -> void:
	enemy=get_parent()
	body=Node3D.new();add_child(body)
	var file := "rootling-combat-prototype.glb"
	if enemy.is_heart: file = "root-heart-combat.glb"
	elif enemy.enemy_title == "IRONROOT GUARD": file = "ironroot-guard-combat.glb"
	elif enemy.enemy_title == "MORTARCAP": file = "mortarcap-combat.glb"
	var path := "res://assets/owner/atlas/" + file
	combat_mode = ResourceLoader.exists(path)
	if not combat_mode: path = "res://assets/environment/moonlit-ruins/root_heart.glb" if enemy.is_heart else "res://assets/environment/moonlit-ruins/rootling.glb"
	var creature=load(path).instantiate()
	body.add_child(creature)
	if combat_mode:
		combat_player = find_animation_player(creature)
		if supports_combat_clips():
			combat_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			combat_player.get_animation("WalkInPlace").loop_mode = Animation.LOOP_LINEAR
			play_clip("Idle")
	# Blender -Y front exports to Godot +Z, matching the existing motion rig.
	if enemy.is_heart: scale=Vector3.ONE * 1.7
	elif enemy.enemy_title == "IRONROOT GUARD": scale=Vector3.ONE * 1.5
	elif enemy.enemy_title == "MORTARCAP": scale=Vector3.ONE * 1.3

func _process(delta: float) -> void:
	if supports_combat_clips():
		visual_hold = maxf(0, visual_hold-delta)
		if enemy.dead:
			return
		var horizontal_speed_sq := Vector2(enemy.velocity.x, enemy.velocity.z).length_squared()
		if horizontal_speed_sq > 0.01:
			body.rotation.y = atan2(enemy.velocity.x, enemy.velocity.z)
		if visual_hold > 0.0 or enemy.stagger > 0.0 or enemy.windup >= 0.0 or enemy.attack_recovery > 0.0:
			return
		if horizontal_speed_sq > 0.01 and enemy.root_time <= 0.0:
			play_clip("WalkInPlace")
		else:
			play_clip("Idle")
		return
	time += delta
	var next_tick := int(time*8)
	if next_tick == tick:
		return
	tick = next_tick
	if enemy.hit_flash>0.12:
		body.scale=Vector3(1.12,0.9,1.12)
		return
	var breathing := sin(tick*0.6)
	body.scale.y = 1.0+breathing*0.05
	if not enemy.is_heart:
		body.rotation.y = atan2(enemy.velocity.x,enemy.velocity.z)
		body.position.y = absf(breathing)*0.07
	if enemy.windup >= 0.0:
		body.scale = Vector3(1.15,0.8,1.15)
	elif enemy.slow_time > 0 or enemy.root_time>0:
		body.scale = Vector3(1,0.9,1)
	else:
		body.scale.x = 1.0
		body.scale.z = 1.0

func supports_combat_clips() -> bool:
	if not combat_mode or combat_player == null:
		return false
	for clip in ["Idle", "WalkInPlace", "AttackSwipe", "HitFlinch", "Death"]:
		if not combat_player.has_animation(clip):
			return false
	return true

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null

func play_clip(clip: String, speed: float = 1.0) -> void:
	if combat_player == null or not combat_player.has_animation(clip):
		return
	if clip == current_clip and combat_player.is_playing():
		return
	current_clip = clip
	combat_player.play(clip, 0.12, speed)

func begin_attack(windup: float) -> void:
	if not supports_combat_clips():
		return
	current_clip = ""
	var duration := combat_player.get_animation("AttackSwipe").length
	visual_hold = windup + 0.25
	play_clip("AttackSwipe", duration / maxf(0.4, visual_hold))

func begin_hit() -> void:
	if not supports_combat_clips():
		return
	current_clip = ""
	var duration := combat_player.get_animation("HitFlinch").length
	visual_hold = 0.5
	play_clip("HitFlinch", duration / 0.5)

func begin_death() -> void:
	if not supports_combat_clips():
		return
	current_clip = ""
	var duration := combat_player.get_animation("Death").length
	play_clip("Death", duration / 1.5)

