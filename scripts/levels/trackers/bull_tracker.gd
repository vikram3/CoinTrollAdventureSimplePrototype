extends ObjectiveTracker
## Checkpoint 10: survive four charges from the invulnerable bulls and defeat
## both minor bulls.

@export var need_charges: int = 4
@export var need_minor_defeats: int = 2
@export var minor_type: String = "minor_bull"

var charges: int = 0
var minor_defeats: int = 0


func _on_setup() -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		var c := n as Charger
		if c and c.invulnerable:
			c.charge_finished.connect(_on_charge_finished)
	level.enemy_defeated.connect(_on_enemy_defeated)


func _on_charge_finished(_charger: Charger) -> void:
	if level and level.finished:
		return
	charges += 1
	if charges <= need_charges and level:
		level.announce("Charge survived %d/%d" % [charges, need_charges])


func _on_enemy_defeated(enemy: EnemyBase) -> void:
	if enemy.enemy_type == minor_type:
		minor_defeats += 1


func is_complete() -> bool:
	return charges >= need_charges and minor_defeats >= need_minor_defeats


func get_objective_text() -> String:
	return "Survive bull charges (%d/%d) + defeat minor bulls (%d/%d)" % [mini(charges, need_charges), need_charges, mini(minor_defeats, need_minor_defeats), need_minor_defeats]
