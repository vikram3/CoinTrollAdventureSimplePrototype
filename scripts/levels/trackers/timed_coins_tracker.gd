extends ObjectiveTracker
## Level 14: survive the timer and have enough coins when it runs out.

@export var seconds: float = 60.0
@export var need_coins: int = 20

var _left: float = 0.0


func _on_setup() -> void:
	seconds *= GameState.timer_mult()
	need_coins = maxi(1, roundi(need_coins * GameState.coin_target_mult()))
	_left = seconds


func _physics_process(delta: float) -> void:
	if level == null or level.finished:
		return
	_left = maxf(_left - delta, 0.0)
	if _left <= 0.0 and coins() < need_coins:
		level.fail("Not enough coins!", false)


func is_complete() -> bool:
	return _left <= 0.0 and coins() >= need_coins


func get_objective_text() -> String:
	return "Survive %d s + collect %d coins" % [int(seconds), need_coins]


func get_timer_value() -> float:
	return _left


func get_coin_target() -> int:
	return need_coins
