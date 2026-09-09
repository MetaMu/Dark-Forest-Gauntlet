extends CharacterBody3D
## Shared damage interface for the stationary Heart and mobile Rootling proxies.
var is_heart: bool = false
var health: float = 30.0
var max_health: float = 30.0
var dead: bool = false
var encounter: Node
var label: Label3D
var material: StandardMaterial3D
var cooldown: float = 1.0
var windup: float = -1.0
var target: CharacterBody3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.85 if is_heart else 0.35
	collision.shape = shape
	collision.position.y = shape.radius
	add_child(collision)
	var mesh := MeshInstance3D.new()
	mesh.name = "PlaceholderRootHeart" if is_heart else "PlaceholderRootling"
	var sphere := SphereMesh.new()
	sphere.radius = shape.radius
	sphere.height = shape.radius * 2.0
	mesh.mesh = sphere
	mesh.position.y = shape.radius
	material = StandardMaterial3D.new()
	material.albedo_color = Color("a8466a") if is_heart else Color("b9bc73")
	mesh.material_override = material
	add_child(mesh)
	label = Label3D.new()
	label.position.y = shape.radius * 2.0 + 0.6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 36
	label.pixel_size = 0.012
	add_child(label)
	update_label()

func _physics_process(delta: float) -> void:
	if dead or encounter == null or encounter.state != encounter.State.COMBAT:
		return
	cooldown -= delta
	if is_heart:
		if cooldown <= 0.0:
			cooldown = 5.0
			encounter.spawn_rootling(position + Vector3(1.4, 0, 0))
		return
	if windup >= 0.0:
		windup -= delta
		if windup <= 0.0:
			if is_instance_valid(target) and not target.downed and position.distance_to(target.position) < 1.5:
				target.take_damage(12.0)
			windup = -1.0
			cooldown = 1.0
			material.emission_enabled = false
		return
	target = encounter.nearest_survivor(position)
	if target == null:
		return
	var offset := target.position - position
	offset.y = 0.0
	if offset.length() <= 1.15:
		velocity = Vector3.ZERO
		if cooldown <= 0.0:
			windup = 0.55
			material.emission_enabled = true
			material.emission = Color("f44d35")
	else:
		velocity = offset.normalized() * 2.3
		velocity.y = -2.0
		move_and_slide()

func take_damage(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	update_label()
	if health <= 0.0:
		dead = true
		queue_free()

func update_label() -> void:
	if label != null:
		label.text = "%s  %d" % ["ROOT HEART" if is_heart else "Rootling", int(health)]
