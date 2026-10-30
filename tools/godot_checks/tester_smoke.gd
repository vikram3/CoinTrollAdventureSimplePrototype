extends SceneTree

func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var state := root.get_node("GameState")
	var problems := 0
	for info in StoryData.LEVELS:
		var scene := load(str(info.scene)) as PackedScene
		var level = scene.instantiate()
		root.add_child(level)
		current_scene = level
		if level.player:
			level.player.invincible = true
		for frame in 12:
			await physics_frame
		if level.objective_type == 6 and level.tracker == null:
			problems += 1
		if int(info.number) >= 6 and not state.has_ability("triple_jump"):
			problems += 1
		level.pause_menu.open()
		if not paused:
			problems += 1
		level.pause_menu.resume()
		level.queue_free()
		await process_frame
	print("TESTER SMOKE: 24 runtime scenes, pause/resume and ability checks; problems=", problems)
	quit(1 if problems else 0)
