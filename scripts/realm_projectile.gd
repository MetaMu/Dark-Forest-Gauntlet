extends Node3D
const FX = preload("res://scripts/combat_fx.gd")
const VFX = preload("res://scripts/realm_vfx.gd")
var nature := true
var direction := Vector3.FORWARD
var speed := 16.0
var damage := 22.0
var lifetime := 0.8
var encounter: Node3D
var source := Vector3.ZERO
var color := Color("9cce7e")
var remaining_hits := 1
var hit_ids: Array[int] = []

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var shape := PrismMesh.new()
	shape.size=Vector3(.20,.12,.62)
	mesh.mesh = shape
	mesh.material_override = FX.material(Color("e3ffb0") if nature else Color("fff0b0"))
	add_child(mesh)
	if direction.length_squared() > 0.0:
		look_at(global_position + direction)
	VFX.projectile_trail(encounter,self,color,.23 if nature else .14)

func _physics_process(delta: float) -> void:
	if encounter.state != encounter.State.COMBAT:
		queue_free()
		return
	lifetime -= delta
	var next := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		VFX.impact(encounter, global_position, color,nature)
		queue_free()
		return
	for enemy in encounter.enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy.get_instance_id() in hit_ids:
			continue
		var center: Vector3 = enemy.global_position + Vector3.UP * 0.7
		var closest := Geometry3D.get_closest_point_to_segment(center,global_position,next)
		if closest.distance_to(center) < (0.95 if enemy.is_heart else 0.5):
			hit_ids.append(enemy.get_instance_id())
			enemy.take_damage(damage, source)
			FX.number(encounter, enemy.global_position, str(int(damage)), color)
			VFX.impact(encounter, enemy.global_position, color,nature)
			remaining_hits-=1
			if remaining_hits<=0:
				queue_free()
				return
	global_position = next
	if lifetime <= 0.0:
		queue_free()
