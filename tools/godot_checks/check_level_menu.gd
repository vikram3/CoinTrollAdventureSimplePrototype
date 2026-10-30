extends SceneTree

func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._open_select()
	for frame in 5:
		await process_frame
	var problems := 0
	if menu.grid.get_child_count() != StoryData.count():
		problems += 1
	for index in StoryData.count():
		var button = menu.grid.get_child(index)
		if button.text != "%02d" % (index + 1) or button.disabled:
			problems += 1
		if not menu.get_global_rect().encloses(button.get_global_rect()):
			problems += 1
	menu._show_info(24)
	if not menu.select_info.text.contains("Ahrena"):
		problems += 1
	print("LEVEL MENU: 24 selectable buttons, bounds and final-level details; problems=", problems)
	quit(1 if problems else 0)
