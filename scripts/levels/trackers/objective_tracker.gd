class_name ObjectiveTracker
extends Node
## Base for custom "Event" objectives (type 6): a defeat, a wave clear, etc.

var level: Level = null


func setup(owner_level: Level) -> void:
	level = owner_level
	_on_setup()


func _on_setup() -> void:
	pass


func is_complete() -> bool:
	return false


func get_objective_text() -> String:
	return ""


func get_coin_target() -> int:
	return 0


func get_timer_value() -> float:
	return -1.0


func coins() -> int:
	return GameState.coins
