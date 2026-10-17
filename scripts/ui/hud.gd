class_name GameHUD
extends CanvasLayer
## In-game HUD: coin counter (top left), objective and timer (top centre),
## health pips and pause button (top right). Fades when CT is under it.

signal pause_pressed

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

var _timer_value: float = -1.0
var _pulse: float = 0.0
var _announce_time: float = 0.0
var _fade_target: float = 1.0
var _bump_tween: Tween = null

@onready var coin_label: Label = %CoinLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var timer_label: Label = %TimerLabel
@onready var health_box: HBoxContainer = %HealthBox
@onready var pause_button: Button = %PauseButton
@onready var announce_label: Label = %AnnounceLabel
@onready var top_left: Control = %TopLeft
@onready var top_center: Control = %TopCenter
@onready var top_right: Control = %TopRight


func _ready() -> void:
	add_to_group("hud")
	pause_button.pressed.connect(_on_pause_button_pressed)
	timer_label.visible = false
	announce_label.modulate.a = 0.0


func set_coins(count: int, target: int) -> void:
	coin_label.text = ("%d / %d" % [count, target]) if target > 0 else str(count)


## Screen position the flying coins head for.
func coin_screen_position() -> Vector2:
	return coin_label.get_global_rect().get_center()


## Counter bump when a coin lands.
func bump_coins() -> void:
	if _bump_tween and _bump_tween.is_valid():
		_bump_tween.kill()
	coin_label.pivot_offset = coin_label.size * 0.5
	coin_label.scale = Vector2.ONE
	coin_label.modulate = Color(1.0, 1.0, 0.5)
	_bump_tween = create_tween()
	_bump_tween.tween_property(coin_label, "scale", Vector2(1.4, 1.4), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bump_tween.tween_property(coin_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bump_tween.parallel().tween_property(coin_label, "modulate", Color.WHITE, 0.3)


func set_objective(text: String) -> void:
	if objective_label.text != text:
		objective_label.text = text


func set_timer(seconds: float) -> void:
	_timer_value = seconds
	timer_label.visible = seconds >= 0.0
	if seconds >= 0.0:
		timer_label.text = "%d s" % ceili(seconds)


func set_health(current: int, maximum: int) -> void:
	var i := 0
	for pip in health_box.get_children():
		var rect := pip as TextureRect
		if rect == null:
			continue
		rect.visible = i < maximum
		rect.texture = heart_full if i < current else heart_empty
		i += 1


func announce(text: String, duration: float = 1.8) -> void:
	announce_label.text = text
	announce_label.modulate.a = 1.0
	_announce_time = duration


func set_overlap_fade(player_screen_pos: Vector2) -> void:
	_fade_target = 0.35 if player_screen_pos.y < 140.0 else 1.0


func _process(delta: float) -> void:
	_pulse += delta
	if _timer_value >= 0.0 and _timer_value <= 5.0:
		var k := (sin(_pulse * 12.0) + 1.0) * 0.5
		timer_label.modulate = Color(1.0, 0.35, 0.3).lerp(Color.WHITE, k)
	else:
		timer_label.modulate = Color.WHITE
	if _announce_time > 0.0:
		_announce_time -= delta
		if _announce_time < 0.5:
			announce_label.modulate.a = maxf(_announce_time / 0.5, 0.0)
	for c: Control in [top_left, top_center, top_right]:
		c.modulate.a = move_toward(c.modulate.a, _fade_target, delta * 3.0)


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
