extends Level
## Collect scattered ballast, then deposit it at the rescue marker.

func get_objective_text() -> String:
	return "Recover %d ballast coins, then reach the rescue marker (%d/%d)" % [coin_target, mini(GameState.coins, coin_target), coin_target]


func on_goal_reached() -> void:
	if GameState.coins < coin_target:
		announce("The ship is still unstable! Recover more ballast coins.")
		return
	announce("Ballast secured — Reina can land the ship!")
	super.on_goal_reached()
