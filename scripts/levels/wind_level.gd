extends Level
## Telegraph gusts before applying them. Shelter grants a safe timing window.

var _last_phase: int = -1


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not player or finished:
		return
	var phase := int(elapsed) % 8
	if phase != _last_phase:
		_last_phase = phase
		if phase == 3:
			announce("Wind incoming! Find shelter or brace for the gust.")
		elif phase == 4:
			announce("GUST >>>")
		elif phase == 7:
			announce("Wind easing — move!")
	player.push_x = 260.0 if phase >= 4 and phase < 7 and not player.is_hidden else 0.0
