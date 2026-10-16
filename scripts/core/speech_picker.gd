class_name SpeechPicker
extends RefCounted
## Picks a random line from a pool and never repeats the last pick of that pool.

var _last: Dictionary = {}


func pick(pool_name: String, lines: PackedStringArray) -> String:
	if lines.is_empty():
		return ""
	if lines.size() == 1:
		return lines[0]
	var last: int = int(_last.get(pool_name, -1))
	var idx := randi() % lines.size()
	if idx == last:
		idx = (idx + 1 + randi() % (lines.size() - 1)) % lines.size()
	_last[pool_name] = idx
	return lines[idx]
