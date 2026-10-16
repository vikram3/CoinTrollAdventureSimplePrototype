extends Node
## Tilting deck for checkpoint 15: sways the camera and pushes CT downhill.

@export var amplitude_degrees: float = 4.0
@export var period: float = 5.0
@export var push_strength: float = 90.0

var _t: float = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	var s := sin(_t * TAU / period)
	var p := get_tree().get_first_node_in_group("player") as PlayerBase
	if p == null:
		return
	p.push_x = -s * push_strength
	if p.camera:
		p.camera.ignore_rotation = false
		p.camera.rotation = deg_to_rad(amplitude_degrees) * s
