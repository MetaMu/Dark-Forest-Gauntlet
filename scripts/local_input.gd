extends RefCounted
## Separate keyboard action sets; negative IDs other than -1/-2 have no input.
## A disconnected controller retains its slot and safely stops moving.

const KEYS = [[KEY_A,KEY_D,KEY_W,KEY_S,KEY_F,KEY_G,KEY_E,KEY_Q],[KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_J,KEY_K,KEY_U,KEY_L]]
const ACTIONS = ["left","right","up","down","attack","power","revive","switch"]
static var settings_path := "user://keyboard.cfg"

static func configure() -> void:
	var config:=ConfigFile.new();config.load(settings_path)
	for team in 2:
		for i in ACTIONS.size():
			var action:=action_name(-1-team,ACTIONS[i])
			if InputMap.has_action(action): continue
			InputMap.add_action(action)
			var event:=InputEventKey.new();event.physical_keycode=config.get_value("keys",action,KEYS[team][i])
			InputMap.action_add_event(action,event)

static func key_for(device: int, action: String) -> int:
	return InputMap.action_get_events(action_name(device,action))[0].physical_keycode

static func rebind(device: int, action: String, key: int) -> bool:
	if key in [0,KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_F11,KEY_T,KEY_SPACE,KEY_SHIFT,KEY_R,KEY_1,KEY_2,KEY_3,KEY_4]: return false
	for team in 2:
		for other in ACTIONS:
			if key_for(-1-team,other)==key and (device!=-1-team or other!=action): return false
	var name:=action_name(device,action)
	InputMap.action_erase_events(name)
	var event:=InputEventKey.new();event.physical_keycode=key
	InputMap.action_add_event(name,event)
	var config:=ConfigFile.new();config.load(settings_path)
	config.set_value("keys",name,key);config.save(settings_path)
	return true

static func key_label(device: int, action: String) -> String:
	return OS.get_keycode_string(key_for(device,action))

static func action_name(device: int, action: String) -> String:
	return "keyboard_%d_%s" % [-device,action]

static func pressed(device: int, action: String) -> bool:
	return device in [-1,-2] and Input.is_action_pressed(action_name(device,action))

static func movement(device: int) -> Vector2:
	if device in [-1,-2]:
		return Vector2(float(pressed(device,"right"))-float(pressed(device,"left")),float(pressed(device,"down"))-float(pressed(device,"up"))).limit_length()
	if device<0: return Vector2.ZERO
	if not Input.get_connected_joypads().has(device):
		return Vector2.ZERO
	var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
	var dpad := Vector2(
		float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)),
		float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP))
	)
	if dpad.length_squared() > 0.0:
		return dpad.limit_length()
	if stick.length() <= 0.2:
		return Vector2.ZERO
	return stick.normalized() * minf((stick.length() - 0.2) / 0.8, 1.0)

static func attack(device: int) -> bool:
	if device < 0:
		return pressed(device,"attack") or (device==-1 and Input.is_physical_key_pressed(KEY_SPACE))
	return Input.get_connected_joypads().has(device) and Input.is_joy_button_pressed(device, JOY_BUTTON_X)

static func interact(device: int) -> bool:
	if device < 0:
		return pressed(device,"revive")
	return Input.get_connected_joypads().has(device) and Input.is_joy_button_pressed(device, JOY_BUTTON_A)

static func power(device: int) -> bool:
	if device < 0:
		return pressed(device,"power") or (device==-1 and Input.is_physical_key_pressed(KEY_SHIFT))
	return Input.get_connected_joypads().has(device) and Input.is_joy_button_pressed(device,JOY_BUTTON_B)
