extends Sprite2D

@onready var trigger: Area2D = $Area2D

# Hardcoded destinations
const PORTAL_1_POS: Vector2 = Vector2(12200, -2750)
const PORTAL_2_POS: Vector2 = Vector2(23350, -900)

func _ready() -> void:
	if trigger:
		trigger.body_entered.connect(_on_trigger_body_entered)

func _on_trigger_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var target: Vector2 = _get_target_from_name()
		body.global_position = target
		if "velocity" in body:
			body.velocity = Vector2.ZERO
		if "_spawn_pos" in body:
			body._spawn_pos = target
		print("Teleported via %s to %s" % [name, target])

func _get_target_from_name() -> Vector2:
	match name:
		"Portal 1":
			return PORTAL_1_POS
		"Portal 2":
			return PORTAL_2_POS
		_:
			return Vector2.ZERO
