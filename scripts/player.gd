extends CharacterBody3D

const LocalInput = preload("res://scripts/local_input.gd")
const POWER_RADIUS := 4.0
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
var class_id: int = 0
var last_input := Vector2(0, 1)
var attack_windup := 0.0
var pending_attack := false
var stepped_combat := false
var foot_clock := 0.0
const POWER_COOLDOWNS := [7.0,9.0,10.0,14.0]
var power_cooldown := 0.0
var power_held := false
var dash_time := 0.0
var dash_direction := Vector3.ZERO
var team_id := -1
var controlled := true
var companion_input := Vector2.ZERO
var companion_attack := false
signal attack_requested(player)
signal power_requested(player)
signal dash_finished(player)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	power_cooldown=maxf(0.0,power_cooldown-delta)
	var was_dashing:=dash_time>0.0
	dash_time=maxf(0.0,dash_time-delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	if pending_attack:
		attack_windup = maxf(0.0, attack_windup - delta)
		if attack_windup <= 0.0:
			pending_attack = false
			if not downed and combat_enabled:
				attack_flash = 0.22
				attack_requested.emit(self)
	if attack_visual != null:
		attack_visual.visible = attack_flash > 0.0
	var input := LocalInput.movement(device) if controlled else companion_input
	if downed:
		input = Vector2.ZERO
	var direction := Vector3(input.x + input.y, 0.0, input.y - input.x).normalized() * input.length()
	if input.length_squared() > 0.01:
		last_input = input
	velocity.x = move_toward(velocity.x, direction.x * speed, 30.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 30.0 * delta)
	if was_dashing and not downed:
		velocity.x=dash_direction.x*16.0
		velocity.z=dash_direction.z*16.0
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if was_dashing and dash_time<=0.0 and not downed:
		dash_finished.emit(self)
	if direction.length_squared() > 0.01 and visual != null:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-14.0 * delta))
	if combat_enabled and (LocalInput.attack(device) if controlled else companion_attack):
		try_attack()
	var power_down:=controlled and LocalInput.power(device)
	if stepped_combat and combat_enabled and power_down and not power_held:
		try_power()
	power_held=power_down

func try_power() -> bool:
	if downed or not combat_enabled or power_cooldown>0.0 or not stepped_combat:
		return false
	power_cooldown=POWER_COOLDOWNS[class_id]
	attack_flash=0.32
	power_requested.emit(self)
	return true

func try_attack() -> bool:
	if downed or not combat_enabled or attack_cooldown > 0.0:
		return false
	attack_cooldown = [0.55, 0.7, 1.1, 0.9][class_id] if stepped_combat else 0.5
	if stepped_combat:
		if get_parent().has_method("prepare_attack"):
			get_parent().prepare_attack(self)
		pending_attack = true
		attack_windup = 0.12
	else:
		attack_flash = 0.28
		attack_requested.emit(self)
	return true

func take_damage(amount: float) -> void:
	if downed or invulnerability > 0.0 or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invulnerability = 0.6
	if get_parent().has_method("play_sound"):
		get_parent().play_sound("hurt", -12.0)
	if health <= 0.0:
		downed = true
		pending_attack = false
		dash_time=0.0
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

func footstep() -> void:
	if get_parent().has_method("play_sound"):
		get_parent().play_sound("step", -26.0)
