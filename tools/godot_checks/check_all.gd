extends SceneTree

var _frames := 0

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	var files: Array[String] = []
	_collect("res://", files)
	for f in files:
		load(f)
	print("CHECKED %d scripts" % files.size())
	quit(0)
	return false

func _collect(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if d.current_is_dir():
			if not name.begins_with(".") and name != "_to_delete":
				_collect(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = d.get_next()
