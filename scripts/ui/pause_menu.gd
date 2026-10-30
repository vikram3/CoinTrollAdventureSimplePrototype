class_name PauseMenu
extends CanvasLayer
## Pause menu: Resume, Restart level, Quit to menu.

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
var _mission: Label


func _ready() -> void:
	visible = false
	_mission = Label.new()
	_mission.custom_minimum_size = Vector2(480, 0)
	_mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission.add_theme_font_size_override("font_size", 18)
	resume_button.get_parent().add_child(_mission)
	resume_button.get_parent().move_child(_mission, 1)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	if GameState.TESTER_BUILD:
		for offset in [1, -1]:
			var button := Button.new()
			button.text = "Next level / skip (F3)" if offset == 1 else "Previous level (F4)"
			button.custom_minimum_size.y = 44
			button.pressed.connect(GameState.tester_jump.bind(offset))
			resume_button.get_parent().add_child(button)
			resume_button.get_parent().move_child(button, restart_button.get_index() + 1)
		quit_button.text = "Main menu / level selection"
	if GameState.DEV_TOOLS:
		_add_dev_skip_button()


## TEMPORARY dev button: completes the current level right away (see GameState.DEV_TOOLS).
func _add_dev_skip_button() -> void:
	var skip := Button.new()
	skip.name = "DevSkipButton"
	skip.text = "DEV: Skip level"
	skip.pressed.connect(_on_dev_skip_pressed)
	var parent := resume_button.get_parent()
	parent.add_child(skip)
	parent.move_child(skip, resume_button.get_index() + 1)


func _on_dev_skip_pressed() -> void:
	resume()
	GameState.debug_skip_level()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		resume()
	elif _can_pause():
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func _can_pause() -> bool:
	if get_tree().paused or Transition.busy:
		return false
	var lvl := get_tree().get_first_node_in_group("level") as Level
	return lvl == null or not lvl.finished


func open() -> void:
	if visible or not _can_pause():
		return
	var level := get_tree().get_first_node_in_group("level") as Level
	if level:
		_mission.text = "%02d — %s\n%s\n\n%s\nGreen outlines: shelter. Orange cannon lines: incoming fire." % [level.level_number, level.level_name, level.trigger_line, level.get_objective_text()]
	visible = true
	get_tree().paused = true
	Sfx.play("select")
	resume_button.grab_focus()


func resume() -> void:
	visible = false
	get_tree().paused = false


func _on_restart_pressed() -> void:
	visible = false
	GameState.restart_level()


func _on_quit_pressed() -> void:
	visible = false
	GameState.go_to_main_menu()
