extends Node2D
## Fires light projectiles in a fixed direction on a timer (deck hazards).

@export var projectile_scene: PackedScene
@export var direction: Vector2 = Vector2.LEFT
@export var interval: float = 3.5
@export var first_delay: float = 2.0
@export var speed: float = 220.0
@export var lifetime: float = 14.0

var _cd: float = 0.0
var _visible_time: float = 0.0


func _ready() -> void:
	interval *= GameState.hazard_timer_mult()
	_cd = first_delay
	z_index = 3
	var label := Label.new()
	label.text = "CANNON"
	label.position = Vector2(-40, -62)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)


func _draw() -> void:
	var aim := direction.normalized()
	draw_circle(Vector2.ZERO, 25.0, Color("35465e"))
	draw_arc(Vector2.ZERO, 26.0, 0, TAU, 24, Color("f6c65b"), 3.0)
	draw_line(Vector2.ZERO, aim * 40.0, Color("899db5"), 17.0)
	if _cd <= 0.75:
		draw_line(aim * 42.0, aim * 165.0, Color(1, 0.35, 0.15, 0.65), 3.0)
		draw_circle(aim * 42.0, 8.0, Color("ffb347"))


func _physics_process(delta: float) -> void:
	# A source must be on screen long enough to read before it can shoot.
	var screen_pos := get_global_transform_with_canvas().origin
	if not get_viewport_rect().grow(-32).has_point(screen_pos):
		_visible_time = 0.0
		_cd = maxf(_cd, 0.8)
		return
	_visible_time += delta
	queue_redraw()
	if _visible_time < 0.8:
		return
	_cd -= delta
	if _cd > 0.0 or projectile_scene == null:
		return
	_cd = interval
	var proj := projectile_scene.instantiate() as Projectile
	proj.direction = direction.normalized()
	proj.speed = speed
	proj.lifetime = lifetime
	proj.shooter = self
	get_parent().add_child(proj)
	proj.global_position = global_position + direction.normalized() * 44.0
