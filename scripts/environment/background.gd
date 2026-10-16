extends CanvasLayer
## Screen-space background with a gentle horizontal parallax scroll.

@export var texture: Texture2D
@export var parallax: float = 0.2
@export var tint: Color = Color.WHITE

@onready var rect: TextureRect = $Rect


func _ready() -> void:
	if texture:
		rect.texture = texture
	rect.modulate = tint
	rect.stretch_mode = TextureRect.STRETCH_TILE
	_resize()
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	var vs := get_viewport().get_visible_rect().size
	var tw := 1280.0
	if rect.texture:
		tw = float(rect.texture.get_width())
	rect.position.y = 0.0
	rect.size = Vector2(vs.x + tw * 2.0, maxf(vs.y, 720.0))


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null or rect.texture == null:
		return
	var tw := float(rect.texture.get_width())
	rect.position.x = -fposmod(cam.get_screen_center_position().x * parallax, tw)
