class_name PauseMenu
extends CanvasLayer
## Pause menu: Resume, Restart level, Quit to menu.

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
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
