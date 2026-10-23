class_name TutorialStation
extends Area2D
## A tutorial checkpoint in a level. When CT walks through it he hears the lesson once,
## and the ability it teaches is unlocked for the rest of the game.

@export var lesson: String = ""
## Ability granted by this station (see GameState.has_ability). Empty for a plain lesson.
@export var ability: String = ""
@export var size: Vector2 = Vector2(160, 420)

var _done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _done or not (body is PlayerBase):
		return
	_done = true
	var player := body as PlayerBase
	if ability != "":
		GameState.unlock_ability(ability)
	if lesson != "":
		player.say(lesson, 5.0)
