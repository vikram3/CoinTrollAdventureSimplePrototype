extends Node2D
## Moves a background decoration (the rival silhouette, Horn in the trees).

@export var move_velocity: Vector2 = Vector2(180, 0)
@export var travel: float = 3000.0
@export var loop: bool = false
@export var bob: float = 4.0

var _start: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_start = position


func _process(delta: float) -> void:
	_t += delta
	if _offset.length() < travel:
		_offset += move_velocity * delta
	elif loop:
		_offset = Vector2.ZERO
	position = _start + _offset + Vector2(0, sin(_t * 8.0) * bob)
