extends ObjectiveTracker
## Level 10: defeat one of each enemy type.

@export var required_types: PackedStringArray = ["tank", "speed", "projectile"]

var _defeated: Dictionary = {}


func _on_setup() -> void:
	level.enemy_defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(enemy: EnemyBase) -> void:
	if enemy.enemy_type in required_types and not _defeated.has(enemy.enemy_type):
		_defeated[enemy.enemy_type] = true
		level.announce("%s type down!" % enemy.enemy_type.capitalize())


func is_complete() -> bool:
	for t in required_types:
		if not _defeated.has(t):
			return false
	return true


func get_objective_text() -> String:
	var parts: PackedStringArray = []
	for t in required_types:
		parts.append("%s %s" % [t.capitalize(), "[x]" if _defeated.has(t) else "[ ]"])
	return "Defeat each type:  " + "   ".join(parts)
