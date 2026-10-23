extends SceneTree
## Dev harness: load one level (set LEVEL_SCENE below) and run it for a few seconds to catch runtime errors.

const LEVEL_SCENE := "res://scenes/levels/chapter_02/level_04_shadow_arena.tscn"
var _frames := 0
var _level: Node = null

func _initialize() -> void:
	_level = (load(LEVEL_SCENE) as PackedScene).instantiate()
	root.add_child(_level)

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 60:
		print("abilities before: %s" % str(root.get_node("GameState").abilities.keys()))
	if _frames >= 300:
		print("ran %d frames ok, abilities now: %s" % [_frames, str(root.get_node("GameState").abilities.keys())])
		quit()
	return false
