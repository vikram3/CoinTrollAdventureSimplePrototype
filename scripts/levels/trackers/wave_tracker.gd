extends ObjectiveTracker
## Levels 06 and 12: clear every wave (and optionally collect coins).

@export var spawner_path: NodePath
@export var need_coins: int = 0
@export var label: String = "Clear the waves"

var _spawner: WaveSpawner = null


func _on_setup() -> void:
	_spawner = get_node_or_null(spawner_path) as WaveSpawner


func is_complete() -> bool:
	return _spawner != null and _spawner.finished and coins() >= need_coins


func get_objective_text() -> String:
	var total := 0
	var cleared := 0
	if _spawner:
		total = _spawner.wave_counts.size()
		cleared = total if _spawner.finished else maxi(_spawner.current_wave, 0)
	var text := "%s (%d/%d)" % [label, cleared, total]
	if need_coins > 0:
		text = "Collect %d coins + %s" % [need_coins, text.to_lower()]
	return text


func get_coin_target() -> int:
	return need_coins
