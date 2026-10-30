extends Control
## Plays a cinematic between levels: still panels with speech, a slow
## camera push and a fade. Space/Enter advances a line. Esc or the SKIP button skips.

@onready var background: ColorRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var frame: Control = %Frame
@onready var art: TextureRect = %Art
@onready var caption: Label = %Caption
@onready var bubble: Control = %Bubble
@onready var speaker_label: Label = %SpeakerLabel
@onready var line_label: Label = %LineLabel

## Preview one cinematic on its own: type a key from StoryData.CINEMATICS here
## (e.g. "intro"), then press F6 with this scene open. Leave it empty in the game.
@export var preview_key: String = ""

var _previewing: bool = false
var _advance: bool = false
var _skip: bool = false
var _done: bool = false
## Panel-level navigation: -1 = previous panel, 1 = next panel, 0 = none.
var _nav: int = 0


func _ready() -> void:
	get_tree().paused = false
	bubble.modulate.a = 0.0
	frame.modulate.a = 0.0
	if GameState.pending_cinematic == "" and preview_key != "":
		GameState.pending_cinematic = preview_key
		_previewing = true
	var data := StoryData.get_cinematic(GameState.pending_cinematic)
	if data.is_empty():
		push_warning("Cinematic key not found: '%s'" % GameState.pending_cinematic)
	if data.is_empty():
		_finish.call_deferred()
		return
	title_label.text = str(data.get("title", ""))
	_add_skip_button()
	_add_nav_buttons()
	_run(data)


## PREV and NEXT buttons along the bottom corners, for touch and mouse players.
func _add_nav_buttons() -> void:
	_add_button("PrevButton", "<< PREV", Vector2(20.0, -150.0), Vector2(-20.0, -150.0), func(): _go(-1))
	_add_button("NextButton", "NEXT >>", Vector2(-190.0, -150.0), Vector2(-20.0, -150.0), func(): _go(1))


func _add_button(node_name: String, text: String, left_top: Vector2, right_top: Vector2, on_press: Callable) -> void:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(170, 64)
	b.add_theme_font_size_override("font_size", 26)
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	if node_name == "PrevButton":
		b.anchor_left = 0.0
		b.anchor_right = 0.0
		b.offset_left = left_top.x
		b.offset_right = left_top.x + 170.0
	else:
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.offset_left = -190.0
		b.offset_right = -20.0
	b.offset_top = left_top.y
	b.offset_bottom = left_top.y + 64.0
	b.pressed.connect(on_press)
	add_child(b)
	b.z_index = 10


## Jumps to the previous or next panel (dir -1 / 1).
func _go(dir: int) -> void:
	_nav = dir
	_advance = true


## On-screen SKIP button for touch and mouse players (Esc / pause also skip).
func _add_skip_button() -> void:
	var skip := Button.new()
	skip.name = "SkipButton"
	skip.text = "SKIP >>"
	skip.focus_mode = Control.FOCUS_NONE
	skip.custom_minimum_size = Vector2(170, 64)
	skip.add_theme_font_size_override("font_size", 26)
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -190.0
	skip.offset_right = -20.0
	skip.offset_top = 20.0
	skip.offset_bottom = 84.0
	skip.pressed.connect(_on_skip_pressed)
	add_child(skip)
	skip.z_index = 10


func _on_skip_pressed() -> void:
	_skip = true
	_advance = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_skip = true
		_advance = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_go(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_go(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_advance = true
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_advance = true


func _run(data: Dictionary) -> void:
	var panels: Array = data.get("panels", [])
	# Flatten the cinematic into steps: one "panel" step, then one "line" step per line.
	var steps: Array = []
	var panel_starts: Array = []
	for pi in panels.size():
		panel_starts.append(steps.size())
		steps.append({"kind": "panel", "panel": pi})
		for li in (panels[pi].get("lines", []) as Array).size():
			steps.append({"kind": "line", "panel": pi, "line": li})
	var idx := 0
	while idx < steps.size() and not _skip:
		var step: Dictionary = steps[idx]
		var pi: int = step.panel
		var lines: Array = panels[pi].get("lines", [])
		if step.kind == "panel":
			await _show_panel(panels[pi])
			if lines.is_empty():
				await _wait(2.5)
		else:
			var line: Array = lines[step.line]
			_show_line(line)
			var hold := clampf(2.0 + str(line[1]).length() * 0.035, 2.0, 4.0)
			await _wait(hold)
			var last_in_panel: bool = step.line == lines.size() - 1
			if last_in_panel and _nav == 0 and not _skip:
				var tw := create_tween()
				tw.tween_property(frame, "modulate:a", 0.0, 0.3)
				tw.parallel().tween_property(bubble, "modulate:a", 0.0, 0.3)
				await tw.finished
		if _nav != 0:
			var target := pi + _nav
			_nav = 0
			_advance = false
			if target < 0:
				target = 0
			if target >= panels.size():
				break
			idx = panel_starts[target]
			continue
		idx += 1
	_finish()


func _show_panel(panel: Dictionary) -> void:
	background.color = Color.html(str(panel.get("bg", "#101020")))
	caption.text = str(panel.get("caption", ""))
	var art_path: String = str(panel.get("art", ""))
	art.texture = null
	if art_path != "" and ResourceLoader.exists(art_path):
		art.texture = load(art_path) as Texture2D
	art.pivot_offset = art.size * 0.5
	art.scale = Vector2.ONE
	bubble.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(frame, "modulate:a", 1.0, 0.35)
	var push := create_tween()
	push.tween_property(art, "scale", Vector2(1.08, 1.08), 6.0)
	await tw.finished


func _show_line(line: Array) -> void:
	var speaker := str(line[0])
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	line_label.text = str(line[1])
	bubble.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bubble, "modulate:a", 1.0, 0.2)


func _wait(seconds: float) -> void:
	_advance = false
	var t := 0.0
	while t < seconds and not _advance and _nav == 0 and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()


func _finish() -> void:
	if _done:
		return
	_done = true
	if _previewing:
		GameState.pending_cinematic = ""
		GameState.go_to_main_menu()
		return
	GameState.cinematic_finished()
