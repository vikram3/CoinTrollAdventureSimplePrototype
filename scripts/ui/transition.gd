extends CanvasLayer
## Scene transitions: a short fade with the level name. Autoloaded as "Transition".

var busy: bool = false

@onready var fade: ColorRect = $Fade
@onready var title: Label = $Title


func _ready() -> void:
	fade.modulate.a = 0.0
	title.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(path: String, text: String = "") -> void:
	if busy:
		return
	busy = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	title.text = text
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fade, "modulate:a", 1.0, 0.35)
	tw.tween_property(title, "modulate:a", 1.0 if text != "" else 0.0, 0.35)
	await tw.finished
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Could not load scene: %s" % path)
	await get_tree().create_timer(0.7 if text != "" else 0.15).timeout
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(fade, "modulate:a", 0.0, 0.4)
	tw2.tween_property(title, "modulate:a", 0.0, 0.4)
	await tw2.finished
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
