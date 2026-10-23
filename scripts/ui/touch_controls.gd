extends Control
## On-screen touch buttons for phones and tablets. Each button presses the same
## InputMap action the keyboard uses, so gameplay code does not change. Several
## fingers can hold different buttons at once. Hidden on desktop unless always_show is set.

@export var mode: String = "platformer"   # platformer | alex | topdown
@export var always_show: bool = false

var _buttons: Array = []        # each: {"action", "label", "center", "radius"}
var _pressed: Array = []        # per button: bool
var _owner_of: Dictionary = {}  # touch index -> button index
var _active: bool = false
## Virtual joystick for movement (left side of the screen).
const STICK_RADIUS := 110.0
const STICK_DEAD := 0.15
var _stick_center: Vector2 = Vector2(170.0, 500.0)
var _stick_touch: int = -1
var _stick_vec: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_active = always_show or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	visible = _active
	set_process_input(_active)
	resized.connect(_build_layout)
	_build_layout()


func _build_layout() -> void:
	for i in _pressed.size():
		if _pressed[i]:
			_drive_actions(str(_buttons[i]["action"]), false)
	_buttons.clear()
	_pressed.clear()
	_owner_of.clear()
	_stick_center = Vector2(170.0, get_viewport().get_visible_rect().size.y - 170.0)
	_stick_touch = -1
	_set_stick(Vector2.ZERO)
	var s: Vector2 = get_viewport().get_visible_rect().size
	var w: float = s.x
	var h: float = s.y
	match mode:
		"topdown":
			var cx: float = 170.0
			var cy: float = h - 170.0
			_add("attack", "HIT", Vector2(w - 170.0, h - 150.0), 74.0)
		"alex":
			_add("attack", "HIT", Vector2(w - 250.0, h - 120.0), 72.0)
			_add("jump", "JUMP", Vector2(w - 100.0, h - 120.0), 72.0)
			_add("move_down", "SHIELD", Vector2(w - 250.0, h - 270.0), 58.0)
			_add("move_up", "BOW", Vector2(w - 100.0, h - 270.0), 58.0)
		_:
			_add("attack", "HIT", Vector2(w - 250.0, h - 120.0), 72.0)
			_add("jump", "JUMP", Vector2(w - 100.0, h - 120.0), 72.0)
			_add("move_down", "HIDE", Vector2(w - 410.0, h - 120.0), 58.0)
			_add("dash", "DASH", Vector2(w - 100.0, h - 270.0), 58.0)
			_add("block", "BLOCK", Vector2(w - 250.0, h - 270.0), 58.0)
			_add("move_down+attack", "DIVE", Vector2(w - 410.0, h - 270.0), 58.0)
	queue_redraw()


func _add(action: String, label: String, center: Vector2, radius: float) -> void:
	_buttons.append({"action": action, "label": label, "center": center, "radius": radius})
	_pressed.append(false)


func _button_at(pos: Vector2) -> int:
	for i in _buttons.size():
		var c: Vector2 = _buttons[i]["center"]
		var r: float = _buttons[i]["radius"]
		if pos.distance_to(c) <= r:
			return i
	return -1


func _set_button(i: int, down: bool) -> void:
	if _pressed[i] == down:
		return
	_pressed[i] = down
	_drive_actions(str(_buttons[i]["action"]), down)
	queue_redraw()


## An action string can name several actions joined by "+" (e.g. "move_down+attack" for the dive button).
func _drive_actions(action_list: String, down: bool) -> void:
	for action in action_list.split("+"):
		if down:
			Input.action_press(action)
		else:
			Input.action_release(action)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		if t.pressed:
			if _stick_touch == -1 and t.position.distance_to(_stick_center) < STICK_RADIUS * 1.6:
				_stick_touch = t.index
				_update_stick(t.position)
				get_viewport().set_input_as_handled()
				return
			var hit: int = _button_at(t.position)
			if hit >= 0:
				_owner_of[t.index] = hit
				_set_button(hit, true)
				get_viewport().set_input_as_handled()
		elif t.index == _stick_touch:
			_stick_touch = -1
			_set_stick(Vector2.ZERO)
		elif _owner_of.has(t.index):
			_set_button(int(_owner_of[t.index]), false)
			_owner_of.erase(t.index)
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if d.index == _stick_touch:
			_update_stick(d.position)
			get_viewport().set_input_as_handled()
			return
		if _owner_of.has(d.index):
			var cur: int = int(_owner_of[d.index])
			var now: int = _button_at(d.position)
			if now != cur:
				_set_button(cur, false)
				if now >= 0:
					_owner_of[d.index] = now
					_set_button(now, true)
				else:
					_owner_of.erase(d.index)


## Turns a touch position into a stick vector (length 0..1) and presses the matching move actions.
func _update_stick(pos: Vector2) -> void:
	var v := (pos - _stick_center) / STICK_RADIUS
	if v.length() > 1.0:
		v = v.normalized()
	_set_stick(v)


func _set_stick(v: Vector2) -> void:
	if v.length() < STICK_DEAD:
		v = Vector2.ZERO
	_stick_vec = v
	_press_axis("move_left", "move_right", v.x)
	# Side-scrolling modes only steer left and right; move_up and move_down stay free for jump and hide.
	if mode == "topdown":
		_press_axis("move_up", "move_down", v.y)
	queue_redraw()


## Presses the negative action for negative values and the positive action for positive ones.
func _press_axis(neg_action: String, pos_action: String, value: float) -> void:
	if value < 0.0:
		Input.action_press(neg_action, -value)
		Input.action_release(pos_action)
	elif value > 0.0:
		Input.action_press(pos_action, value)
		Input.action_release(neg_action)
	else:
		Input.action_release(neg_action)
		Input.action_release(pos_action)


func _draw() -> void:
	if not _active:
		return
	var font: Font = ThemeDB.fallback_font
	draw_circle(_stick_center, STICK_RADIUS, Color(1, 1, 1, 0.14))
	draw_arc(_stick_center, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.6), 3.0)
	var knob := _stick_center + _stick_vec * STICK_RADIUS * 0.6
	draw_circle(knob, 42.0, Color(1, 1, 1, 0.45 if _stick_touch != -1 else 0.25))
	for i in _buttons.size():
		var c: Vector2 = _buttons[i]["center"]
		var r: float = _buttons[i]["radius"]
		var down: bool = _pressed[i]
		draw_circle(c, r, Color(1, 1, 1, 0.45 if down else 0.22))
		draw_arc(c, r, 0.0, TAU, 40, Color(1, 1, 1, 0.75), 3.0)
		var label: String = _buttons[i]["label"]
		draw_string(font, c + Vector2(-r, 8.0), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 22, Color(1, 1, 1, 0.9))
