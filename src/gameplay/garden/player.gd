class_name GardenPlayer
extends CharacterBody3D
## First-person player for the garden (Story 001, design/game-brief.md).
##
## Mouse look + WASD/ZQSD (physical keys) + arrows, gamepad left stick move and
## right stick look. All tuning comes from the "player" block of
## res://assets/data/garden.json via [method configure].

## Emitted when the mouse is captured (true) or released (false).
signal mouse_capture_changed(captured: bool)

var _move_speed: float = 3.5
var _acceleration: float = 14.0
var _gravity: float = 20.0
var _mouse_sensitivity: float = 0.0022
var _gamepad_look_speed: float = 2.6
var _deadzone: float = 0.2
var _pitch_limit: float = deg_to_rad(80.0)
var _bounds_min: Vector2 = Vector2(-9.0, -9.0)
var _bounds_max: Vector2 = Vector2(9.0, 9.0)
var _pitch: float = 0.0
var _camera: Camera3D


## Applies tuning values. [param cfg] is the "player" dictionary of garden.json;
## [param bounds_min] / [param bounds_max] clamp the player on the XZ plane.
## Must be called before the node enters the tree.
func configure(cfg: Dictionary, bounds_min: Vector2, bounds_max: Vector2) -> void:
	_move_speed = float(cfg.get("move_speed", _move_speed))
	_acceleration = float(cfg.get("acceleration", _acceleration))
	_gravity = float(cfg.get("gravity", _gravity))
	_mouse_sensitivity = float(cfg.get("mouse_sensitivity", _mouse_sensitivity))
	_gamepad_look_speed = float(cfg.get("gamepad_look_speed", _gamepad_look_speed))
	_deadzone = float(cfg.get("gamepad_deadzone", _deadzone))
	_pitch_limit = deg_to_rad(float(cfg.get("pitch_limit_degrees", 80.0)))
	_bounds_min = bounds_min
	_bounds_max = bounds_max

	var height: float = float(cfg.get("capsule_height", 1.8))
	var radius: float = float(cfg.get("capsule_radius", 0.35))
	var shape := CapsuleShape3D.new()
	shape.height = height
	shape.radius = radius
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = Vector3(0.0, height * 0.5, 0.0)
	add_child(collider)

	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, float(cfg.get("eye_height", 1.6)), 0.0)
	_camera.current = true
	_camera.fov = 75.0
	add_child(_camera)

	var spawn: Array = cfg.get("spawn", [0.0, 7.0])
	position = Vector3(float(spawn[0]), 0.1, float(spawn[1]))
	# Initial view: yaw about Y (0 = facing -Z, towards the garden), slight downward pitch.
	rotation.y = deg_to_rad(float(cfg.get("spawn_yaw_degrees", 0.0)))
	_pitch = clampf(deg_to_rad(float(cfg.get("spawn_pitch_degrees", 0.0))), -_pitch_limit, _pitch_limit)
	_camera.rotation.x = _pitch


## The first-person camera (the interaction ray starts here).
func get_camera() -> Camera3D:
	return _camera


## True while the mouse is captured (look/interact active).
func is_mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Turns the view towards a world-space point (used by debug captures).
func face_point(world_point: Vector3) -> void:
	var eye: Vector3 = _camera.global_position
	var dir: Vector3 = world_point - eye
	rotation.y = atan2(-dir.x, -dir.z)
	var flat: float = Vector2(dir.x, dir.z).length()
	_pitch = clampf(atan2(dir.y, flat), -_pitch_limit, _pitch_limit)
	_camera.rotation.x = _pitch


func _ready() -> void:
	_set_mouse_captured(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture"):
		_set_mouse_captured(Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_set_mouse_captured(true)
		# This click only recaptures the mouse; it must not also interact (Story 002).
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_apply_look(motion.relative.x * _mouse_sensitivity, motion.relative.y * _mouse_sensitivity)


func _physics_process(delta: float) -> void:
	# Gamepad right-stick look.
	var look: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down", _deadzone)
	if look != Vector2.ZERO:
		_apply_look(look.x * _gamepad_look_speed * delta, look.y * _gamepad_look_speed * delta)

	# Planar movement relative to facing.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back", _deadzone)
	var direction: Vector3 = (global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target: Vector3 = direction * _move_speed * minf(input_dir.length(), 1.0)
	var weight: float = clampf(_acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target.x, weight)
	velocity.z = lerpf(velocity.z, target.z, weight)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()

	# Keep the player inside the garden (belt and braces with the fence colliders).
	position.x = clampf(position.x, _bounds_min.x, _bounds_max.x)
	position.z = clampf(position.z, _bounds_min.y, _bounds_max.y)


func _apply_look(yaw_delta: float, pitch_delta: float) -> void:
	rotate_y(-yaw_delta)
	_pitch = clampf(_pitch - pitch_delta, -_pitch_limit, _pitch_limit)
	_camera.rotation.x = _pitch


func _set_mouse_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	mouse_capture_changed.emit(captured)
