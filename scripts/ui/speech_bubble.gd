class_name SpeechBubble
extends Node2D
## Rounded speech bubble with a short tail. One bubble per speaker; a new line
## replaces the old one. Never blocks input.

const SCENE_PATH := "res://scenes/ui/speech_bubble.tscn"
const WRAP_LENGTH := 26
const WRAP_WIDTH := 240.0

var _timer: float = 0.0

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label


static func say(speaker: Node2D, text: String, duration: float = 2.5, height: float = 70.0) -> SpeechBubble:
	if speaker == null or not is_instance_valid(speaker) or text == "":
		return null
	var bubble := speaker.get_node_or_null("SpeechBubble") as SpeechBubble
	if bubble == null:
		var scene := load(SCENE_PATH) as PackedScene
		bubble = scene.instantiate() as SpeechBubble
		bubble.name = "SpeechBubble"
		speaker.add_child(bubble)
	bubble.position = Vector2(0, -height)
	bubble.show_text(text, duration)
	return bubble


func show_text(text: String, duration: float) -> void:
	_timer = duration
	visible = true
	modulate.a = 1.0
	if text.length() > WRAP_LENGTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(WRAP_WIDTH, 0)
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2.ZERO
	label.text = text
	panel.reset_size()
	_layout()
	await get_tree().process_frame
	if is_instance_valid(self):
		panel.reset_size()
		_layout()


func _layout() -> void:
	var s := panel.size
	panel.position = Vector2(-s.x * 0.5, -s.y - 10.0)


func _process(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer -= delta
	if _timer < 0.25:
		modulate.a = maxf(_timer / 0.25, 0.0)
	if _timer <= 0.0:
		visible = false
