# Bav.gd (attach to bav root)
extends Node2D
class_name Bav

@export var tex_happy: Texture2D
@export var tex_sad: Texture2D
@onready var sprite: Sprite2D = $Sprite2D

func set_happy(state: bool) -> void:
	if state and tex_happy:
		sprite.texture = tex_happy
	elif not state and tex_sad:
		sprite.texture = tex_sad
