extends SceneTree
## Dev harness: play one cinematic headless and report runtime errors. Edit KEY to test another.

const KEY := "pink_girl_arrives"
var _frames := 0

func _initialize() -> void:
	root.get_node("GameState").pending_cinematic = KEY
	var scene := (load("res://scenes/cinematics/cinematic.tscn") as PackedScene).instantiate()
	root.add_child(scene)

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 120:
		# Press NEXT, then PREV, through the same path the buttons use.
		var c := root.get_child(root.get_child_count() - 1)
		c.call("_go", 1)
	if _frames == 240:
		var c2 := root.get_child(root.get_child_count() - 1)
		c2.call("_go", -1)
	if _frames >= 900:
		print("cinematic ran %d frames ok" % _frames)
		quit()
	return false
