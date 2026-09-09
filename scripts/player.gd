extends CharacterBody3D

const LocalInput = preload("res://scripts/local_input.gd")
@export var device: int = -1
@export var speed: float = 5.0
var visual: Node3D
var health: float = 100.0
var downed: bool = false
var combat_enabled: bool = false
var attack_cooldown: float = 0.0
var invulnerability: float = 0.0
var revive_progress: float = 0.0
var attack_flash: float = 0.0
var attack_visual: MeshInstance3D
signal attack_requested(player)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	if attack_visual != null:
		attack_visual.visible = attack_flash > 0.0
	var input := LocalInput.movement(device)
	if downed:
		input = Vector2.ZERO
	var direction := Vector3(input.x + input.y, 0.0, input.y - input.x).normalized() * input.length()
	velocity.x = move_toward(velocity.x, direction.x * speed, 30.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 30.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if direction.length_squared() > 0.01 and visual != null:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-14.0 * delta))
	if combat_enabled and LocalInput.attack(device):
		try_attack()

func try_attack() -> bool:
	if downed or not combat_enabled or attack_cooldown > 0.0:
		return false
	attack_cooldown = 0.5
	attack_flash = 0.13
	attack_requested.emit(self)
	return true

func take_damage(amount: float) -> void:
	if downed or invulnerability > 0.0 or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invulnerability = 0.6
	if health <= 0.0:
		downed = true
		velocity = Vector3.ZERO
		if visual != null:
			visual.scale.y = 0.3

func revive() -> void:
	if not downed:
		return
	health = 40.0
	downed = false
	revive_progress = 0.0
	invulnerability = 2.0
	if visual != null:
		visual.scale.y = 1.0
