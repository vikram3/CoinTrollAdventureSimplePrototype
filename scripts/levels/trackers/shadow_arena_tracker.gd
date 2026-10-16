extends ObjectiveTracker
## Checkpoint 03: collect the coins and avoid the shadow shockwaves.

@export var need_coins: int = 30
@export var need_bursts: int = 5
@export var spawner_path: NodePath

var bursts_avoided: int = 0


func _on_setup() -> void:
	var spawner := get_node_or_null(spawner_path) as ShadowSpawner
	if spawner:
		spawner.burst_finished.connect(_on_burst)


func _on_burst(hit_player: bool) -> void:
	if hit_player:
		return
	bursts_avoided += 1
	if bursts_avoided <= need_bursts and level:
		level.announce("Burst avoided %d/%d" % [bursts_avoided, need_bursts])


func is_complete() -> bool:
	return coins() >= need_coins and bursts_avoided >= need_bursts


func get_objective_text() -> String:
	return "Collect %d coins + avoid %d bursts (%d/%d)" % [need_coins, need_bursts, mini(bursts_avoided, need_bursts), need_bursts]


func get_coin_target() -> int:
	return need_coins
