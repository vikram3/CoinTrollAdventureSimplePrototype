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
			Input.action_release(str(_buttons[i]["action"]))
	_buttons.clear()
	_pressed.clear()
	_owner_of.clear()
	var s: Vector2 = get_viewport().get_visible_rect().size
	var w: float = s.x
	var h: float = s.y
	match mode:
		"topdown":
			var cx: float = 170.0
			var cy: float = h - 170.0
			_add("move_up", "UP", Vector2(cx, cy - 92.0), 56.0)
			_add("move_down", "DN", Vector2(cx, cy + 92.0), 56.0)
			_add("move_left", "<", Vector2(cx - 92.0, cy), 56.0)
			_add("move_right", ">", Vector2(cx + 92.0, cy), 56.0)
			_add("attack", "HIT", Vector2(w - 170.0, h - 150.0), 74.0)
		"alex":
			_add("move_left", "<", Vector2(120.0, h - 120.0), 64.0)
			_add("move_right", ">", Vector2(260.0, h - 120.0), 64.0)
			_add("attack", "HIT", Vector2(w - 250.0, h - 120.0), 72.0)
			_add("jump", "JUMP", Vector2(w - 100.0, h - 120.0), 72.0)
			_add("move_down", "SHIELD", Vector2(w - 250.0, h - 270.0), 58.0)
			_add("move_up", "BOW", Vector2(w - 100.0, h - 270.0), 58.0)
		_:
			_add("move_left", "<", Vector2(120.0, h - 120.0), 64.0)
			_add("move_right", ">", Vector2(260.0, h - 120.0), 64.0)
			_add("attack", "HIT", Vector2(w - 250.0, h - 120.0), 72.0)
			_add("jump", "JUMP", Vector2(w - 100.0, h - 120.0), 72.0)
			_add("move_down", "HIDE", Vector2(w - 410.0, h - 120.0), 58.0)
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
	var action: String = str(_buttons[i]["action"])
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		if t.pressed:
			var hit: int = _button_at(t.position)
			if hit >= 0:
				_owner_of[t.index] = hit
				_set_button(hit, true)
				get_viewport().set_input_as_handled()
		elif _owner_of.has(t.index):
			_set_button(int(_owner_of[t.index]), false)
			_owner_of.erase(t.index)
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
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


func _draw() -> void:
	if not _active:
		return
	var font: Font = ThemeDB.fallback_font
	for i in _buttons.size():
		var c: Vector2 = _buttons[i]["center"]
		var r: float = _buttons[i]["radius"]
		var down: bool = _pressed[i]
		draw_circle(c, r, Color(1, 1, 1, 0.45 if down else 0.22))
		draw_arc(c, r, 0.0, TAU, 40, Color(1, 1, 1, 0.75), 3.0)
		var label: String = _buttons[i]["label"]
		draw_string(font, c + Vector2(-r, 8.0), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 22, Color(1, 1, 1, 0.9))
