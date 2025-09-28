# Player.gd — detects the Portal and teleports to (671, 243)
class_name Player
extends CharacterBody2D

signal love_changed(new_love: int)

# --- Movement ---
const BASE_SPEED: float = 800.0
const JUMP_VELOCITY: float = -900.0

@export var slow_speed_mult: float = 0.75  # speed after >3 deaths

# --- Gravity tuning ---
const GRAVITY: float = 1600.0
const FALL_MULT: float = 1.6
const JUMP_CUTOFF_MULT: float = 2.0

# --- Jump forgiveness ---
const COYOTE_TIME: float = 0.10
const JUMP_BUFFER: float = 0.10
const MAX_AIR_JUMPS: int = 2   # triple jump (2 in air)

# --- Player state ---
var isBlind: bool = false  # becomes true after >5 deaths

# --- Respawn / deaths ---
@export var death_y: float = 1500.0
var death_count: int = 0
var _spawn_pos: Vector2

# --- Love (collectible) ---
@export var love_max: int = 50
var love: int = 0

# --- UI (optional) ---
@export var love_meter_path: NodePath
@onready var love_meter: LoveMeter = get_node_or_null(love_meter_path) as LoveMeter
@export var love_label_path: NodePath
@onready var love_label: Label = get_node_or_null(love_label_path) as Label
@export var death_label_path: NodePath
@onready var death_label: Label = get_node_or_null(death_label_path) as Label

# --- Blind overlay (optional) ---
@export var blind_overlay_path: NodePath
@onready var blind_overlay: ColorRect = get_node_or_null(blind_overlay_path) as ColorRect

# --- Scene nodes ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vab_blind: Sprite2D = get_node_or_null("VabBlind")

# --- Jump internals ---
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _air_jumps_left: int = MAX_AIR_JUMPS

# --- Portal target ---
const PORTAL_DEST: Vector2 = Vector2(671, 243)

func _ready() -> void:
	_spawn_pos = global_position
	if love_meter:
		love_meter.set_love_max(love_max, false)
		love_meter.set_love(love)
	_update_love_ui()
	_update_death_ui()
	_update_status_from_deaths()
	_apply_blind_state()
	love_changed.emit(love)

func _physics_process(delta: float) -> void:
	# Floor state & timers
	if is_on_floor():
		_coyote = COYOTE_TIME
		_air_jumps_left = MAX_AIR_JUMPS
	else:
		_coyote = max(0.0, _coyote - delta)

	# Overlay
	_apply_blind_state()

	# Buffer jump input
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = max(0.0, _jump_buffer - delta)

	# Balanced gravity
	if not is_on_floor():
		var g := GRAVITY
		if velocity.y > 0.0:
			g *= FALL_MULT
		elif not Input.is_action_pressed("jump"):
			g *= JUMP_CUTOFF_MULT
		velocity.y += g * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	# Jump / triple jump always
	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			_do_jump()
			_coyote = 0.0
			_jump_buffer = 0.0
		elif _air_jumps_left > 0:
			_do_jump()
			_air_jumps_left -= 1
			_jump_buffer = 0.0

	# Horizontal movement (slow after >3 deaths)
	var direction: float = Input.get_axis("left", "right")
	var cur_speed: float = _current_speed()
	if direction != 0.0:
		velocity.x = direction * cur_speed
		animated_sprite.flip_h = direction < 0.0
		if vab_blind:
			vab_blind.flip_h = animated_sprite.flip_h
	else:
		velocity.x = move_toward(velocity.x, 0.0, cur_speed)

	move_and_slide()

	# Animations
	if not is_on_floor():
		if velocity.y < 0.0:
			_safe_play("jump")
		else:
			_safe_play("fall")
	else:
		if abs(velocity.x) > 1.0:
			_safe_play("walk")
		else:
			_safe_play("idle")

	# Fall → die & respawn
	if global_position.y > death_y:
		_death_and_respawn()

func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY

func _safe_play(anim: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim):
		if animated_sprite.animation != anim or not animated_sprite.is_playing():
			animated_sprite.play(anim)
	else:
		if anim in ["jump", "fall"]:
			if abs(velocity.x) > 1.0:
				animated_sprite.play("walk")
			else:
				animated_sprite.play("idle")

# ---------- Love ----------
func add_love(amount: int) -> void:
	love = clamp(love + amount, 0, love_max)
	_update_love_ui()
	love_changed.emit(love)

func _update_love_ui() -> void:
	if love_meter:
		love_meter.set_love_max(love_max, false)
		love_meter.set_love(love)
	if love_label:
		love_label.text = "Love: %d / %d" % [love, love_max]

# ---------- Death / respawn ----------
func _death_and_respawn() -> void:
	death_count += 1
	_update_death_ui()
	_update_status_from_deaths()
	_respawn()

func _update_death_ui() -> void:
	if death_label:
		death_label.text = "Deaths: %d" % death_count

func _update_status_from_deaths() -> void:
	isBlind = death_count > 5
	if blind_overlay:
		blind_overlay.visible = isBlind
	_apply_blind_state()

func _respawn() -> void:
	global_position = _spawn_pos
	velocity = Vector2.ZERO

# ---------- Helpers ----------
func _current_speed() -> float:
	return BASE_SPEED * (slow_speed_mult if death_count > 3 else 1.0)

func _apply_blind_state() -> void:
	if not vab_blind:
		return
	if isBlind:
		vab_blind.show()
		vab_blind.flip_h = animated_sprite.flip_h
	else:
		vab_blind.hide()

# ---------- Player Area2D signals ----------
# If your Player has an Area2D and you connected its **area_entered** signal,
# this will fire when the Player's Area2D overlaps the Portal's Area2D.
func _on_area_2d_area_entered(area: Area2D) -> void:
	# Prefer groups for robustness: add your portal Area2D to group "portal"
	if area.is_in_group("portal") or area.name == "Portal":
		global_position = PORTAL_DEST
		velocity = Vector2.ZERO
		print("Teleported to ", PORTAL_DEST)

# If instead you connected the Player Area2D **body_entered** signal (for PhysicsBody2D portals),
# you can also handle it here:
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("portal") or body.name == "Portal":
		global_position = PORTAL_DEST
		velocity = Vector2.ZERO
		print("Teleported to ", PORTAL_DEST)
