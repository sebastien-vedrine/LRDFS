class_name WateringEffect
extends Node3D
## Short water-droplet shower + splash + ripple on a planted seed (Story 002).
## Self-freeing; place it at the seed position. Tuning from the "settings" block
## of assets/data/flowers.json.

var _settings: Dictionary = {}


## Creates an effect configured from [param settings]; add it to the tree to play it.
static func create(settings: Dictionary) -> WateringEffect:
	var effect := WateringEffect.new()
	effect.name = "WateringEffect"
	effect._settings = settings
	return effect


func _ready() -> void:
	var color: Color = Color.html(str(_settings.get("water_drop_color", "#8fd3ff")))
	var drop_size: float = float(_settings.get("water_drop_size", 0.02))
	var drop := SphereMesh.new()
	drop.radius = drop_size
	drop.height = drop_size * 2.0
	drop.radial_segments = 5
	drop.rings = 3
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = color
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.emission_enabled = true
	drop_mat.emission = color
	drop_mat.emission_energy_multiplier = 1.5
	drop.material = drop_mat

	var rain := CPUParticles3D.new()
	rain.name = "Rain"
	rain.position = Vector3(0.0, float(_settings.get("water_drop_height", 0.9)), 0.0)
	rain.amount = int(_settings.get("water_drop_count", 20))
	rain.lifetime = 0.55
	rain.one_shot = true
	rain.explosiveness = 0.8
	rain.randomness = 0.3
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	rain.emission_sphere_radius = 0.12
	rain.direction = Vector3.DOWN
	rain.spread = 10.0
	rain.initial_velocity_min = 1.2
	rain.initial_velocity_max = 2.0
	rain.gravity = Vector3(0.0, -9.0, 0.0)
	rain.mesh = drop
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)
	rain.emitting = true

	var splash := CPUParticles3D.new()
	splash.name = "Splash"
	splash.position = Vector3(0.0, 0.08, 0.0)
	splash.amount = maxi(int(float(rain.amount) * 0.6), 4)
	splash.lifetime = 0.45
	splash.one_shot = true
	splash.explosiveness = 0.95
	splash.randomness = 0.4
	splash.direction = Vector3.UP
	splash.spread = 65.0
	splash.initial_velocity_min = 0.6
	splash.initial_velocity_max = 1.2
	splash.gravity = Vector3(0.0, -6.0, 0.0)
	splash.mesh = drop
	splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	splash.emitting = false
	add_child(splash)

	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.125
	ring.rings = 16
	ring.ring_segments = 4
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ripple := MeshInstance3D.new()
	ripple.name = "Ripple"
	ripple.mesh = ring
	ripple.material_override = ring_mat
	ripple.position = Vector3(0.0, 0.07, 0.0)
	ripple.scale = Vector3(0.01, 1.0, 0.01)
	ripple.visible = false
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ripple)

	var delay: float = float(_settings.get("water_splash_delay", 0.3))
	var ripple_time: float = float(_settings.get("water_ripple_duration", 0.7))
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_callback(_start_splash.bind(splash, ripple)).set_delay(delay)
	tween.tween_property(ripple, "scale", Vector3(3.2, 1.0, 3.2), ripple_time).set_delay(delay)
	tween.tween_property(ring_mat, "albedo_color:a", 0.0, ripple_time).set_delay(delay)
	tween.tween_callback(queue_free).set_delay(float(_settings.get("water_effect_lifetime", 1.0)) + delay)


func _start_splash(splash: CPUParticles3D, ripple: MeshInstance3D) -> void:
	splash.emitting = true
	ripple.visible = true
