extends Control
## Plays a cinematic between checkpoints: still panels with speech, a slow
## camera push and a fade. Space/Enter advances a line, Esc skips.

@onready var background: ColorRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var frame: Control = %Frame
@onready var art: TextureRect = %Art
@onready var caption: Label = %Caption
@onready var bubble: Control = %Bubble
@onready var speaker_label: Label = %SpeakerLabel
@onready var line_label: Label = %LineLabel

var _advance: bool = false
var _skip: bool = false
var _done: bool = false


func _ready() -> void:
	get_tree().paused = false
	bubble.modulate.a = 0.0
	frame.modulate.a = 0.0
	var data := StoryData.get_cinematic(GameState.pending_cinematic)
	if data.is_empty():
		_finish.call_deferred()
		return
	title_label.text = str(data.get("title", ""))
	_run(data)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_skip = true
		_advance = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_advance = true
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_advance = true


func _run(data: Dictionary) -> void:
	var panels: Array = data.get("panels", [])
	for panel in panels:
		if _skip:
			break
		await _show_panel(panel)
		var lines: Array = panel.get("lines", [])
		for line in lines:
			if _skip:
				break
			_show_line(line)
			var hold := clampf(2.0 + str(line[1]).length() * 0.035, 2.0, 4.0)
			await _wait(hold)
		if not _skip:
			var tw := create_tween()
			tw.tween_property(frame, "modulate:a", 0.0, 0.3)
			tw.parallel().tween_property(bubble, "modulate:a", 0.0, 0.3)
			await tw.finished
	_finish()


func _show_panel(panel: Dictionary) -> void:
	background.color = Color.html(str(panel.get("bg", "#101020")))
	caption.text = str(panel.get("caption", ""))
	var art_path := str(panel.get("art", ""))
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
	while t < seconds and not _advance and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.cinematic_finished()
