extends RefCounted
## Device-owned input: one keyboard and up to three controllers.
## A disconnected controller retains its slot and safely stops moving.

static func movement(device: int) -> Vector2:
	if device < 0:
		return Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		).limit_length()
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
		return Input.is_physical_key_pressed(KEY_SPACE)
	return Input.get_connected_joypads().has(device) and Input.is_joy_button_pressed(device, JOY_BUTTON_X)

static func interact(device: int) -> bool:
	if device < 0:
		return Input.is_physical_key_pressed(KEY_E)
	return Input.get_connected_joypads().has(device) and Input.is_joy_button_pressed(device, JOY_BUTTON_A)
