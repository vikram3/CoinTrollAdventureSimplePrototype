class_name Commenter
extends Node2D
## Background character who comments now and then (crowd, Queen, Lala, Alex).
## Not interactive.

@export var texture: Texture2D
@export var lines: PackedStringArray = []
@export var sequential: bool = false
@export var first_delay: float = 2.0
@export var interval_min: float = 6.0
@export var interval_max: float = 10.0
@export var bubble_height: float = 70.0
@export var flip: bool = false

var _timer: float = 0.0
var _index: int = 0
var _picker := SpeechPicker.new()

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D


func _ready() -> void:
	_timer = first_delay
	if sprite:
		if texture:
			sprite.texture = texture
		sprite.flip_h = flip


func _process(delta: float) -> void:
	if lines.is_empty():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(interval_min, interval_max)
	var text := ""
	if sequential:
		text = lines[_index % lines.size()]
		_index += 1
	else:
		text = _picker.pick("lines", lines)
	SpeechBubble.say(self, text, 2.6, bubble_height)
