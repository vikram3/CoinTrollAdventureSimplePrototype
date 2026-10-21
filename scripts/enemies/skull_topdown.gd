class_name SkullTopDown
extends EnemyBase
## Top-down skull for the level 01 maze. Walks a patrol route and talks as it goes.
## Sees CT only with a clear line of sight (hedges and walls block it), chases him,
## lunges when close, and catches him on contact. Routes around hedges with a grid path,
## so it can return to its patrol points and search spots.

@export var patrol_points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(192, 0)])
@export var patrol_speed: float = 91.0
@export var chase_speed: float = 136.5
@export var detect_range: float = 190.0
@export var search_seconds: float = 6.0
@export var search_radius: float = 120.0
@export var chase_keep_range: float = 360.0
@export var chase_grace: float = 2.5
@export var lunge_range: float = 75.0
@export var lunge_speed: float = 320.0
@export var nav_rect: Rect2 = Rect2(0, 0, 2560, 1920)
@export_group("Dialogue")
@export var lines_patrol: PackedStringArray = ["Hedges, hedges, hedges...", "Quiet night in the maze.", "Did I leave the crypt unlocked?", "My feet hurt. Ten more laps."]
@export var lines_detected: PackedStringArray = ["Hey! Naked troll! Stop right there!", "Oi! Who said you could roam the maze without pants?", "A troll? In MY maze?"]
@export var lines_chase: PackedStringArray = ["Get back here!", "Those coins are not yours!", "You can't run forever, troll!"]
@export var lines_attack: PackedStringArray = ["Take THIS!", "Hold still, troll!", "Those coins are MINE!"]
@export var lines_caught: PackedStringArray = ["Gotcha! Caught you, coin hoarder!", "Hah! Naked AND caught!", "Pay up, troll!"]
@export var lines_lost: PackedStringArray = ["Blasted bushes!", "Where did that naked troll go?!", "He can't have vanished..."]
@export var lines_search: PackedStringArray = ["Come out, come out, wherever you are...", "I know you're in there.", "Nobody hides from me in MY maze."]
@export var lines_give_up: PackedStringArray = ["Hmph. Back to my rounds.", "Not worth it.", "He'll turn up. They always do."]

const NAV_CELL := 32.0
const NAV_CLEAR := 28.0

## Shared by all skulls: 1 = blocked cell (hedge or wall), built once on first use.
static var _nav_blocked := PackedByteArray()
static var _nav_cols: int = 0
static var _nav_rows: int = 0
static var _nav_key: String = ""

var _origin: Vector2 = Vector2.ZERO
var _index: int = 1
var _chasing: bool = false
var _searching: bool = false
var _search_left: float = 0.0
var _search_target: Vector2 = Vector2.ZERO
var _search_pick: float = 0.0
var _grace_left: float = 0.0
var _last_seen: Vector2 = Vector2.ZERO
var _said_search: bool = false
var _chase_bark: float = 0.0
var _patrol_bark: float = 3.0
var _lunge_cd: float = 0.0
var _lunge_t: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO
var _path: PackedVector2Array = PackedVector2Array()
var _path_goal: Vector2 = Vector2.INF
var _path_t: float = 0.0


func _ready() -> void:
	var s := GameState.speed_mult()
	patrol_speed *= s
	chase_speed *= s
	lunge_speed *= s
	use_gravity = false
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_origin = global_position
	if patrol_points.size() < 2:
		patrol_points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])


func _enemy_process(delta: float) -> void:
	_lunge_cd = maxf(_lunge_cd - delta, 0.0)
	var p := get_player()
	var d := INF
	var seen := false
	if p:
		d = global_position.distance_to(p.global_position)
		seen = _clear_line(p.global_position)
	# Hysteresis: once chasing, CT must get well away before the skull gives up on him.
	# Hedges and walls block sight, so CT behind one is not seen; the skull keeps chasing
	# toward where it last saw him for chase_grace seconds before it starts to search.
	var chase_now := seen and (d < detect_range or (_chasing and d < chase_keep_range))

	if chase_now:
		if not _chasing:
			_chasing = true
			_searching = false
			_chase_bark = 0.0
			Sfx.play("alert")
			say_line(lines_detected, "detected", 2.4, true)
		_grace_left = chase_grace
		_last_seen = p.global_position
		_chase_bark -= delta
		if _chase_bark <= 0.0:
			_chase_bark = 3.0
			say_line(lines_chase, "chase", 2.0, true)
		_try_lunge(p, d)
	elif _chasing:
		_grace_left -= delta
		if _grace_left <= 0.0:
			_chasing = false
			_searching = true
			_search_left = search_seconds
			_search_target = _last_seen
			_search_pick = 0.0
			_said_search = false
			Sfx.play("select")
			say_line(lines_lost, "lost", 2.2, true)
	elif _searching:
		_search_left -= delta
		if _search_left <= 0.0:
			_searching = false
			say_line(lines_give_up, "give_up", 2.0, true)

	if _lunge_t > 0.0:
		_lunge_t -= delta
		velocity = _lunge_dir * lunge_speed
		return

	var target: Vector2
	var spd: float
	if _chasing:
		target = p.global_position if p else _last_seen
		spd = chase_speed
	elif _searching:
		# Wander around the spot CT was last seen, so the skull looks for him instead of standing still.
		_search_pick -= delta
		if _search_pick <= 0.0 or global_position.distance_to(_search_target) < 14.0:
			_search_pick = randf_range(1.2, 2.2)
			_search_target = _last_seen + Vector2.from_angle(randf() * TAU) * randf_range(30.0, search_radius)
		target = _search_target
		spd = chase_speed * 0.8
	else:
		target = _origin + patrol_points[_index]
		spd = patrol_speed

	var gap := global_position.distance_to(target)
	if not _chasing and not _searching:
		if gap < 14.0:
			_index = (_index + 1) % patrol_points.size()
			_path.clear()
		_patrol_bark -= delta
		if _patrol_bark <= 0.0:
			_patrol_bark = randf_range(4.0, 7.0)
			say_line(lines_patrol, "patrol")
	if _searching and not _said_search and global_position.distance_to(_last_seen) < 14.0:
		_said_search = true
		say_line(lines_search, "search", 2.2, true)
	velocity = _steer(target, spd, delta)
	if absf(velocity.x) > 1.0:
		face(int(signf(velocity.x)))


## Walk straight at the target when nothing blocks the way, otherwise follow a grid path around hedges.
func _steer(target: Vector2, spd: float, delta: float) -> Vector2:
	if _clear_line(target) and not _segment_hits_bush(target):
		_path.clear()
		var direct := target - global_position
		return direct.normalized() * spd if direct.length() > 1.0 else Vector2.ZERO
	_path_t -= delta
	if _path.is_empty() or _path_t <= 0.0 or _path_goal.distance_to(target) > 48.0:
		_path = _find_path(global_position, target)
		_path_goal = target
		_path_t = 0.5
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 14.0:
		_path.remove_at(0)
	if _path.is_empty():
		return Vector2.ZERO
	return (_path[0] - global_position).normalized() * spd


## Line of sight: nothing on the hedge/wall layer (collision layer 1) between the skull and the point.
func _clear_line(to: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(global_position, to, 1)
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	_ensure_nav()
	var extra := _bush_cells()
	var start := _nearest_free(_cell_of(from), extra)
	var goal := _nearest_free(_cell_of(to), extra)
	if start == Vector2i(-1, -1) or goal == Vector2i(-1, -1):
		return out
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if c == goal:
			break
		for n in [c + Vector2i(1, 0), c + Vector2i(-1, 0), c + Vector2i(0, 1), c + Vector2i(0, -1)]:
			if came.has(n) or not _cell_free(n, extra):
				continue
			came[n] = c
			queue.append(n)
	if not came.has(goal):
		return out
	var cells: Array[Vector2i] = []
	var cur: Vector2i = goal
	while cur != start:
		cells.append(cur)
		cur = came[cur]
	cells.reverse()
	for cell in cells:
		out.append(_cell_center(cell))
	return out


func _ensure_nav() -> void:
	var key := str(nav_rect)
	if key == _nav_key and not _nav_blocked.is_empty():
		return
	_nav_key = key
	_nav_cols = maxi(1, ceili(nav_rect.size.x / NAV_CELL))
	_nav_rows = maxi(1, ceili(nav_rect.size.y / NAV_CELL))
	_nav_blocked = PackedByteArray()
	_nav_blocked.resize(_nav_cols * _nav_rows)
	_nav_blocked.fill(0)
	var space := get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(NAV_CLEAR, NAV_CLEAR)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1
	for r in _nav_rows:
		for c in _nav_cols:
			q.transform = Transform2D(0.0, _cell_center(Vector2i(c, r)))
			if not space.intersect_shape(q, 1).is_empty():
				_nav_blocked[r * _nav_cols + c] = 1


func _cell_of(pos: Vector2) -> Vector2i:
	var l := (pos - nav_rect.position) / NAV_CELL
	return Vector2i(floori(l.x), floori(l.y))


func _cell_center(c: Vector2i) -> Vector2:
	return nav_rect.position + (Vector2(c) + Vector2(0.5, 0.5)) * NAV_CELL


func _cell_free(c: Vector2i, extra: Dictionary = {}) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= _nav_cols or c.y >= _nav_rows:
		return false
	if extra.has(c):
		return false
	return _nav_blocked[c.y * _nav_cols + c.x] == 0


func _nearest_free(c: Vector2i, extra: Dictionary = {}) -> Vector2i:
	if _cell_free(c, extra):
		return c
	for r in range(1, 5):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var n := c + Vector2i(dx, dy)
				if _cell_free(n, extra):
					return n
	return Vector2i(-1, -1)


## Bushes CT is hiding in are solid for skulls, so their cells are blocked while occupied.
func _bush_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for spot in get_tree().get_nodes_in_group("hide_spot"):
		if spot.get("occupied") == true:
			out.append(spot.call("rect"))
	return out


func _bush_cells() -> Dictionary:
	var out := {}
	for r in _bush_rects():
		var a := _cell_of(r.position)
		var b := _cell_of(r.end)
		for x in range(a.x, b.x + 1):
			for y in range(a.y, b.y + 1):
				out[Vector2i(x, y)] = true
	return out


func _segment_hits_bush(to: Vector2) -> bool:
	for r in _bush_rects():
		if r.has_point(to):
			return true
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for i in range(4):
			if Geometry2D.segment_intersects_segment(global_position, to, corners[i], corners[(i + 1) % 4]) != null:
				return true
	return false


func _try_lunge(p: PlayerBase, d: float) -> void:
	if _lunge_cd > 0.0 or d > lunge_range:
		return
	_lunge_cd = 2.2
	_lunge_t = 0.3
	_lunge_dir = (p.global_position - global_position).normalized()
	Sfx.play("swing")
	say_line(lines_attack, "attack", 1.8, true)


func _on_hit_player(_p: PlayerBase) -> void:
	say_line(lines_caught, "caught", 2.4, true)
