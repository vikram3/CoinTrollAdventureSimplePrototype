class_name City
extends Area2D
## A city that enemies can raid. When an enemy walks into it, CT loses 10% of his coins
## (GameState.city_attacked), the same for every CT form. A short cooldown keeps one raid to one hit.

@export var cooldown: float = 3.0

var _cd: float = 0.0


func _ready() -> void:
    collision_layer = 0
    collision_mask = 0xFFFF


func _physics_process(delta: float) -> void:
    _cd = maxf(_cd - delta, 0.0)
    if _cd > 0.0:
        return
    for body in get_overlapping_bodies():
        if body.is_in_group("enemy"):
            _cd = cooldown
            _raid()
            return


func _raid() -> void:
    var lost := GameState.city_attacked()
    Sfx.play("hit")
    var p := get_tree().get_first_node_in_group("player") as PlayerBase
    if p:
        var msg := "The city was raided! Lost %d coins." % lost
        if lost <= 0:
            msg = "The city was raided, but you had no coins to lose."
        p.say(msg, 2.5)
