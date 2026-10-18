class_name FlowerVisual
extends Node3D
## One procedural flower plus its bloom animation (Story 002,
## design/game-brief.md: readable, pretty bloom built from primitives).
##
## The builder ([FlowerFactory]) registers animated parts; [method set_progress]
## (0..1) drives them: stem grows, leaves unfold, petals open. Once the bloom is
## finished call [method start_sway] for a gentle idle sway.

const MODE_STEM: int = 0
const MODE_UNIFORM: int = 1
const MODE_POP: int = 2
const MODE_UNFOLD: int = 3
## Overshoot of the "back" ease used for pops and unfolds.
const BACK_OVERSHOOT: float = 1.2
## Progress at which the sparkles start.
const SPARKLE_START_PROGRESS: float = 0.55

## One animated part: a node whose scale/rotation is driven by progress.
class Part extends RefCounted:
	var node: Node3D
	var start: float = 0.0
	var end: float = 1.0
	var mode: int = 0
	var final_scale: Vector3 = Vector3.ONE
	var from_scale: Vector3 = Vector3.ONE
	var open_rot: Vector3 = Vector3.ZERO
	var closed_rot: Vector3 = Vector3.ZERO

var _parts: Array[Part] = []
var _progress: float = 0.0
var _swaying: bool = false
var _sway_amplitude: float = deg_to_rad(2.0)
var _sway_speed: float = 1.3
var _sway_phase: float = 0.0
var _time: float = 0.0
var _sparkles: CPUParticles3D
var _sparkled: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	var a: float = _time * _sway_speed + _sway_phase
	rotation.z = sin(a) * _sway_amplitude
	rotation.x = cos(a * 0.8 + 1.3) * _sway_amplitude * 0.6


## Current bloom progress in 0..1.
func get_progress() -> float:
	return _progress


## Registers a stem-like part: only Y scale grows (0 -> its scale).
func add_stem(node: Node3D, start: float, end: float) -> void:
	_register(node, MODE_STEM, start, end, Vector3.ONE, Vector3.ZERO)


## Registers a part that grows uniformly from nothing with a soft overshoot.
func add_uniform(node: Node3D, start: float, end: float) -> void:
	_register(node, MODE_UNIFORM, start, end, Vector3.ONE, Vector3.ZERO)


## Registers a part that pops from [param from_factor] x its scale (per axis) to its scale.
func add_pop(node: Node3D, start: float, end: float, from_factor: Vector3) -> void:
	_register(node, MODE_POP, start, end, from_factor, Vector3.ZERO)


## Registers a part that unfolds from [param closed_rot_deg] to the rotation the
## node has now (its open pose), growing slightly as it does.
func add_unfold(node: Node3D, start: float, end: float, closed_rot_deg: Vector3) -> void:
	_register(node, MODE_UNFOLD, start, end, Vector3.ONE, closed_rot_deg)


## Creates the one-shot pollen/sparkle burst emitted when the petals open.
func setup_sparkles(color: Color, settings: Dictionary, origin: Vector3, radius: float) -> void:
	var drop := SphereMesh.new()
	var size: float = float(settings.get("sparkle_size", 0.018))
	drop.radius = size
	drop.height = size * 2.0
	drop.radial_segments = 4
	drop.rings = 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	drop.material = mat
	_sparkles = CPUParticles3D.new()
	_sparkles.name = "Sparkles"
	_sparkles.position = origin
	_sparkles.amount = int(settings.get("sparkle_count", 30))
	_sparkles.lifetime = float(settings.get("sparkle_lifetime", 1.7))
	_sparkles.one_shot = true
	_sparkles.explosiveness = 0.35
	_sparkles.randomness = 0.6
	_sparkles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sparkles.emission_sphere_radius = radius
	_sparkles.direction = Vector3.UP
	_sparkles.spread = 80.0
	_sparkles.initial_velocity_min = 0.1
	_sparkles.initial_velocity_max = 0.45
	_sparkles.gravity = Vector3(0.0, 0.05, 0.0)
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.5
	_sparkles.mesh = drop
	_sparkles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sparkles.emitting = false
	add_child(_sparkles)


## Debug capture helper: keep the sparkles emitting so a frozen bloom still shows them.
func set_sparkles_looping(looping: bool) -> void:
	if _sparkles != null:
		_sparkles.one_shot = not looping


## Applies bloom progress (0..1) to every registered part.
func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	for part: Part in _parts:
		var t: float = clampf((_progress - part.start) / maxf(part.end - part.start, 0.001), 0.0, 1.0)
		part.node.visible = t > 0.0
		if t <= 0.0:
			continue
		match part.mode:
			MODE_STEM:
				part.node.scale = Vector3(part.final_scale.x, part.final_scale.y * _ease_out(t), part.final_scale.z)
			MODE_UNIFORM:
				part.node.scale = part.final_scale * maxf(_ease_back(t), 0.001)
			MODE_POP:
				part.node.scale = (part.final_scale * part.from_scale).lerp(part.final_scale, _ease_back(t))
			MODE_UNFOLD:
				var e: float = _ease_back(t)
				part.node.scale = part.final_scale * maxf(lerpf(0.35, 1.0, e), 0.001)
				part.node.rotation_degrees = part.closed_rot.lerp(part.open_rot, e)
	if _sparkles != null and not _sparkled and _progress >= SPARKLE_START_PROGRESS:
		_sparkled = true
		_sparkles.emitting = true


## Starts the idle sway (call once the bloom has finished).
func start_sway(amplitude_degrees: float, speed: float, phase: float) -> void:
	_sway_amplitude = deg_to_rad(amplitude_degrees)
	_sway_speed = speed
	_sway_phase = phase
	_swaying = true
	set_process(true)


## True once [method start_sway] has been called.
func is_swaying() -> bool:
	return _swaying


func _register(node: Node3D, mode: int, start: float, end: float, from_scale: Vector3, closed_rot_deg: Vector3) -> void:
	var part := Part.new()
	part.node = node
	part.mode = mode
	part.start = start
	part.end = end
	part.final_scale = node.scale
	part.from_scale = from_scale
	part.open_rot = node.rotation_degrees
	part.closed_rot = closed_rot_deg
	_parts.append(part)


func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


func _ease_back(t: float) -> float:
	var c3: float = BACK_OVERSHOOT + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + BACK_OVERSHOOT * pow(t - 1.0, 2.0)
