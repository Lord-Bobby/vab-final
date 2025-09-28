# HeartRoot.gd
extends Node2D

@export var amount: int = 1
@onready var area: Area2D = $Area2D as Area2D

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body: Node2D) -> void:
	if body and body.has_method("add_love"):
		area.set_deferred("monitoring", false) # prevent double-trigger
		body.add_love(amount)
		queue_free()
