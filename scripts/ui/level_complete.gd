class_name LevelCompleteBanner
extends CanvasLayer
## "Level complete" banner: level name, coin total, Continue button.

var _coins: int = 0

@onready var banner: Control = %Banner
@onready var name_label: Label = %NameLabel
@onready var coins_label: Label = %CoinsLabel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)


func open(number: int, level_name: String, coins: int, target: int) -> void:
	_coins = coins
	name_label.text = "Level %02d - %s" % [number, level_name]
	coins_label.text = ("%d / %d coins" % [coins, target]) if target > 0 else ("%d coins" % coins)
	visible = true
	get_tree().paused = true
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.3)
	continue_button.disabled = false
	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	Sfx.play("select")
	GameState.complete_level(_coins)
