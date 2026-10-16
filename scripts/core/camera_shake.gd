extends Camera2D
## Follow camera with a short screen shake for hits and falls.

var _strength: float = 0.0
var _time: float = 0.0
var _duration: float = 0.0


func shake(strength: float = 8.0, duration: float = 0.25) -> void:
	_strength = maxf(_strength, strength)
	_duration = maxf(duration, 0.01)
	_time = _duration


func _process(delta: float) -> void:
	if _time > 0.0:
		_time -= delta
		var k := clampf(_time / _duration, 0.0, 1.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * k
	else:
		offset = Vector2.ZERO
		_strength = 0.0
