extends SceneTree

## Loads every level listed in StoryData.LEVELS and every cinematic key it uses.
## Run: godot --headless --path . --script res://tools/godot_checks/check_levels.gd

var _frames := 0

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	var data := load("res://scripts/data/story_data.gd")
	var levels: Array = data.LEVELS
	var bad := 0
	for info in levels:
		var path: String = info["scene"]
		var ps := load(path) as PackedScene
		if ps == null:
			print("MISSING SCENE  level %d: %s" % [info["number"], path])
			bad += 1
			continue
		var inst := ps.instantiate()
		if inst == null:
			print("CANNOT INSTANCE level %d: %s" % [info["number"], path])
			bad += 1
			continue
		inst.free()
		for key in str(info["cinematic"]).split("+", false):
			if data.get_cinematic(key.strip_edges()).get("panels", []).is_empty():
				print("MISSING CINEMATIC  level %d: '%s'" % [info["number"], key])
				bad += 1
	print("LEVELS CHECKED %d, problems %d" % [levels.size(), bad])
	quit(0)
	return false
