class_name SeedModel
extends Node3D
## A seed built from primitives (Story 002): a soft glowing ellipsoid with a halo.
##
## "Floating" mode (lying in the garden): bobs, spins, small fireflies drift around it.
## "Planted" mode (sitting in the earth): still, dimmer halo, grows a little sprout
## as it is watered and squashes/flashes when it receives water.
## All tuning comes from the "settings" block of assets/data/flowers.json.

var _body: MeshInstance3D
var _halo: MeshInstance3D
var _sprout: Node3D
var _body_mat: StandardMaterial3D
var _halo_mat: StandardMaterial3D
var _floating: bool = true
var _time: float = 0.0
var _flash: float = 0.0
var _flash_decay: float = 2.5
var _glow: float = 2.0
var _bob_amplitude: float = 0.07
var _bob_speed: float = 2.0
var _spin_speed: float = 1.1
var _halo_alpha: float = 0.2
var _bounce_scale: float = 1.35
var _bounce_duration: float = 0.4
var _sprout_height: float = 0.16
var _bounce_tween: Tween


## Builds the meshes. [param floating] true for the pick-up seed, false once planted.
func setup(color: Color, settings: Dictionary, floating: bool) -> void:
	_floating = floating
	_glow = float(settings.get("seed_glow_energy", _glow))
	_bob_amplitude = float(settings.get("seed_bob_amplitude", _bob_amplitude))
	_bob_speed = float(settings.get("seed_bob_speed", _bob_speed))
	_spin_speed = float(settings.get("seed_spin_speed", _spin_speed))
	_halo_alpha = float(settings.get("seed_halo_alpha", _halo_alpha))
	_flash_decay = float(settings.get("water_flash_decay", _flash_decay))
	_bounce_scale = float(settings.get("water_bounce_scale", _bounce_scale))
	_bounce_duration = float(settings.get("water_bounce_duration", _bounce_duration))
	_sprout_height = float(settings.get("sprout_height", _sprout_height))
	var size: float = float(settings.get("seed_size", 0.16))
	var halo_scale: float = float(settings.get("seed_halo_scale", 2.6))
	if not floating:
		size *= 0.75
		halo_scale *= 0.6

	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 5
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = color
	_body_mat.roughness = 0.5
	_body_mat.emission_enabled = true
	_body_mat.emission = color
	_body_mat.emission_energy_multiplier = _glow
	_body = MeshInstance3D.new()
	_body.name = "Body"
	_body.mesh = mesh
	_body.material_override = _body_mat
	_body.scale = Vector3(size * 0.75, size * 1.15, size * 0.75)
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_body)

	_halo_mat = StandardMaterial3D.new()
	_halo_mat.albedo_color = Color(color.r, color.g, color.b, _halo_alpha)
	_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo_mat.no_depth_test = false
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	_halo.mesh = mesh
	_halo.material_override = _halo_mat
	_halo.scale = Vector3.ONE * size * halo_scale
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

	if floating:
		_add_fireflies(color, settings)
		_body.position.y = 0.0
	else:
		_add_sprout()


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * _flash_decay, 0.0)
	var pulse: float = 0.88 + 0.12 * sin(_time * 3.0)
	_body_mat.emission_energy_multiplier = _glow * pulse * (1.0 + _flash * 1.5)
	_halo_mat.albedo_color.a = _halo_alpha * (0.8 + 0.2 * sin(_time * 2.2)) * (1.0 + _flash)
	if _floating:
		_body.position.y = sin(_time * _bob_speed) * _bob_amplitude
		_body.rotation.y += _spin_speed * delta
		_halo.position.y = _body.position.y


## Fades/pops the seed in (used when a new seed appears in the garden).
func appear(duration: float) -> void:
	scale = Vector3.ONE * 0.01
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, maxf(duration, 0.01)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Reaction to a watering: squash-bounce, glow flash.
func react_to_water() -> void:
	_flash = 1.0
	if _bounce_tween != null and _bounce_tween.is_valid():
		_bounce_tween.kill()
	scale = Vector3.ONE
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0) * _bounce_scale, _bounce_duration * 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(self, "scale", Vector3.ONE, _bounce_duration * 0.65) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Sprout size in 0..1 (watering progress).
func set_sprout(amount: float) -> void:
	if _sprout == null:
		return
	var a: float = clampf(amount, 0.0, 1.0)
	_sprout.visible = a > 0.0
	_sprout.scale = Vector3.ONE * maxf(a, 0.001)


## Shrinks the whole seed (0 = full size, 1 = gone) while the flower grows out of it.
func set_shrink(amount: float) -> void:
	if _bounce_tween != null and _bounce_tween.is_valid():
		_bounce_tween.kill()
	var s: float = maxf(1.0 - clampf(amount, 0.0, 1.0), 0.001)
	scale = Vector3.ONE * s
	visible = amount < 1.0


func _add_sprout() -> void:
	_sprout = Node3D.new()
	_sprout.name = "Sprout"
	_sprout.visible = false
	add_child(_sprout)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color("#7fc06a")
	green.roughness = 0.8
	green.cull_mode = BaseMaterial3D.CULL_DISABLED
	var stem := CylinderMesh.new()
	stem.top_radius = 0.004
	stem.bottom_radius = 0.008
	stem.height = _sprout_height
	stem.radial_segments = 4
	stem.rings = 1
	var stem_node := MeshInstance3D.new()
	stem_node.mesh = stem
	stem_node.material_override = green
	stem_node.position = Vector3(0.0, _sprout_height * 0.5, 0.0)
	_sprout.add_child(stem_node)
	var leaf := SphereMesh.new()
	leaf.radius = 0.5
	leaf.height = 1.0
	leaf.radial_segments = 6
	leaf.rings = 3
	for side: float in [-1.0, 1.0]:
		var leaf_node := MeshInstance3D.new()
		leaf_node.mesh = leaf
		leaf_node.material_override = green
		leaf_node.scale = Vector3(_sprout_height * 0.55, 0.012, _sprout_height * 0.28)
		leaf_node.position = Vector3(side * _sprout_height * 0.25, _sprout_height * 0.95, 0.0)
		leaf_node.rotation_degrees = Vector3(0.0, 0.0, side * 25.0)
		_sprout.add_child(leaf_node)
	_sprout.scale = Vector3.ONE * 0.001


func _add_fireflies(color: Color, settings: Dictionary) -> void:
	var drop := SphereMesh.new()
	drop.radius = 0.012
	drop.height = 0.024
	drop.radial_segments = 4
	drop.rings = 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.lightened(0.4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color.lightened(0.4)
	mat.emission_energy_multiplier = 2.5
	drop.material = mat
	var p := CPUParticles3D.new()
	p.name = "Fireflies"
	p.amount = int(settings.get("seed_firefly_count", 6))
	p.lifetime = 2.2
	p.randomness = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.22
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 0.03
	p.initial_velocity_max = 0.1
	p.gravity = Vector3.ZERO
	p.local_coords = true
	p.mesh = drop
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emitting = true
	add_child(p)
