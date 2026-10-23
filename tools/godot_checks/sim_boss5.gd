extends SceneTree
## Dev harness: run level 5 headless, run CT far to the right, and log Big Boss state.

var _frames := 0
var _level: Node = null
var _boss: Node2D = null
var _player: Node2D = null

func _initialize() -> void:
	var packed := load("res://scenes/levels/chapter_02/level_05_big_boss_dodge.tscn") as PackedScene
	_level = packed.instantiate()
	root.add_child(_level)

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _boss == null:
		_boss = _level.get_node_or_null("Enemies/BigBoss1") as Node2D
		_player = _level.get_node_or_null("Player") as Node2D
		return false
	if _frames == 30 and _player:
		_player.global_position = Vector2(4200, 360)
		_player.set("invincible", true)
	if _frames % 30 == 0 and _frames < 1800:
		var st = _boss.get("state")
		var tgt = _boss.call("get_target")
		var hidden = _player.get("is_hidden")
		var dead = _player.get("is_dead")
		if false: print("  target=%s hidden=%s dead=%s on_floor=%s" % [str(tgt != null), str(hidden), str(dead), str(_boss.is_on_floor())])
		print("f=%d boss=(%.0f,%.0f) state=%s vel=(%.0f,%.0f) cd=%.1f player=(%.0f,%.0f)" % [
			_frames, _boss.global_position.x, _boss.global_position.y, str(st),
			_boss.velocity.x, _boss.velocity.y, float(_boss.get("_teleport_cd")),
			_player.global_position.x, _player.global_position.y])
	if _frames >= 1800:
		quit()
	return false
