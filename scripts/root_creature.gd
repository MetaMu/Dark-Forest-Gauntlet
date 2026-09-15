extends Node3D
## Blender-authored bark creatures retain the existing 8 Hz animation cues.
var enemy: CharacterBody3D
var body: Node3D
var time := 0.0
var tick := -1
func _ready() -> void:
	enemy=get_parent()
	body=Node3D.new();add_child(body)
	var path="res://assets/environment/moonlit-ruins/root_heart.glb" if enemy.is_heart else "res://assets/environment/moonlit-ruins/rootling.glb"
	var creature=load(path).instantiate()
	body.add_child(creature)
	# Blender -Y front exports to Godot +Z, matching the existing motion rig.
	if enemy.is_heart: scale=Vector3(1.6,1.8,1.6)

func _process(delta: float) -> void:
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

