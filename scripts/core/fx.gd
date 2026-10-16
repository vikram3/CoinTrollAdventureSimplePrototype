class_name Fx
extends RefCounted
## Small one-shot visual effects (coin sparkles, debris bursts).


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 160.0, lifetime: float = 0.5) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 420)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	p.z_index = 30
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
