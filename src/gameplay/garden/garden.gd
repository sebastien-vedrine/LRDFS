class_name Garden
extends Node3D
## Builds the single 3D garden scene from primitive meshes (Story 001,
## design/game-brief.md: soft, luminous low-poly look, one contained zone).
##
## Everything tunable lives in res://assets/data/garden.json. The six planting
## spots are exposed as Node3D nodes in the group [constant PLOTS_GROUP] so the
## planting story (002) can query them with get_tree().get_nodes_in_group().
## Grass and foliage sway with res://src/gameplay/garden/wind_sway.gdshader.

## Emitted once the garden and its planting spots are built.
signal garden_built(plot_count: int)

## Group name carrying the six planting-spot nodes.
const PLOTS_GROUP: StringName = &"flower_plots"
## Location of the external tuning file.
const CONFIG_PATH: String = "res://assets/data/garden.json"
const WIND_SHADER_PATH: String = "res://src/gameplay/garden/wind_sway.gdshader"
## Ground slab extends well past the terrain so no void is visible.
const GROUND_OVERSIZE: float = 80.0
## The slab top sits this far below y=0; the terrain edge sinks to meet it.
const GROUND_SINK: float = 0.06
const GROUND_THICKNESS: float = 0.4
const WALL_HEIGHT: float = 2.5

var _cfg: Dictionary = {}
var _materials: Dictionary = {}
var _foliage_materials: Dictionary = {}
var _half: Vector2 = Vector2(10.0, 10.0)
var _rng := RandomNumberGenerator.new()
var _height_noise := FastNoiseLite.new()
var _plot_pts: Array[Vector2] = []
var _clouds: Array[Node3D] = []
var _wind_shader: Shader
var _path_noise := FastNoiseLite.new()


func _ready() -> void:
	var root_cfg: Dictionary = _load_config()
	_cfg = root_cfg.get("garden", {})
	var half_arr: Array = _cfg.get("half_extents", [10.0, 10.0])
	_half = Vector2(float(half_arr[0]), float(half_arr[1]))
	_rng.seed = int(_cfg.get("random_seed", 1))
	_wind_shader = load(WIND_SHADER_PATH) as Shader
	for pos: Array in _cfg.get("plot_positions", []):
		_plot_pts.append(Vector2(float(pos[0]), float(pos[1])))
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = _f("terrain_frequency", 0.07)
	_height_noise.seed = int(_cfg.get("random_seed", 1))
	_path_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_path_noise.frequency = 0.7
	_path_noise.seed = int(_cfg.get("random_seed", 1)) + 7

	_build_environment()
	_build_terrain()
	_build_path()
	_build_fence()
	_build_props()
	_build_grass()
	_build_litter()
	_build_clouds()
	var plot_count: int = _build_plots()
	_build_player(root_cfg.get("player", {}))
	garden_built.emit(plot_count)


func _process(delta: float) -> void:
	var speed: float = _f("cloud_drift_speed", 1.0)
	var limit: float = _f("cloud_wrap_x", 130.0)
	for cloud in _clouds:
		cloud.position.x += speed * delta
		if cloud.position.x > limit:
			cloud.position.x = -limit


## Returns the planting-spot nodes (group [constant PLOTS_GROUP]).
func get_plots() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group(PLOTS_GROUP):
		result.append(node as Node3D)
	return result


## Ground height at (x, z): low undulation, flattened around plots, the path and the fence.
func ground_height(x: float, z: float) -> float:
	var n: float = _height_noise.get_noise_2d(x, z) * 0.5 + 0.5
	var h: float = n * _f("terrain_amplitude", 0.4) * _terrain_mask(x, z)
	var outside: float = maxf(absf(x) - _half.x, absf(z) - _half.y)
	return h - GROUND_SINK * smoothstep(1.0, _f("terrain_margin", 3.0), outside)


func _load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("Garden config missing: %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if parsed is Dictionary:
		return parsed
	push_error("Garden config is not a valid JSON object: %s" % CONFIG_PATH)
	return {}


func _f(key: String, fallback: float) -> float:
	return float(_cfg.get(key, fallback))


func _color(key: String, fallback: String) -> Color:
	return Color.html(str(_cfg.get(key, fallback)))


func _path_length() -> float:
	return _half.y * 1.1


func _material(hex: String) -> StandardMaterial3D:
	if not _materials.has(hex):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.html(hex)
		mat.roughness = 1.0
		mat.metallic_specular = 0.2
		_materials[hex] = mat
	return _materials[hex]


## Wind-swaying material for a foliage blob of the given colour and mesh height.
func _foliage_material(color: Color, mesh_height: float) -> ShaderMaterial:
	var key: String = "%s|%.2f" % [color.to_html(false), mesh_height]
	if not _foliage_materials.has(key):
		var mat := ShaderMaterial.new()
		mat.shader = _wind_shader
		_apply_wind_params(mat, _f("foliage_wind_strength", 0.05))
		mat.set_shader_parameter("albedo", color)
		mat.set_shader_parameter("height_offset", mesh_height * 0.5)
		mat.set_shader_parameter("height_range", mesh_height)
		mat.set_shader_parameter("height_power", 1.5)
		mat.set_shader_parameter("tip_brighten", 0.3)
		_foliage_materials[key] = mat
	return _foliage_materials[key]


func _apply_wind_params(mat: ShaderMaterial, strength: float) -> void:
	var dir: Array = _cfg.get("wind_direction", [1.0, 0.35])
	mat.set_shader_parameter("wind_strength", strength)
	mat.set_shader_parameter("wind_speed", _f("wind_speed", 1.2))
	mat.set_shader_parameter("wind_direction", Vector2(float(dir[0]), float(dir[1])))


func _add_mesh(parent: Node, mesh: Mesh, hex: String, pos: Vector3) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _material(hex)
	inst.position = pos
	parent.add_child(inst)
	return inst


func _add_box_collider(parent: Node, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	parent.add_child(body)


func _make_multimesh(mesh: Mesh, transforms: Array[Transform3D], colors: Array[Color]) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	return mm


# --------------------------------------------------------------------------
# Environment, light
# --------------------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = _color("sky_top_color", "#9ccaf0")
	sky_mat.sky_horizon_color = _color("sky_horizon_color", "#fdddc2")
	sky_mat.ground_horizon_color = _color("ground_horizon_color", "#f3dcc0")
	sky_mat.ground_bottom_color = _color("ground_horizon_color", "#f3dcc0")
	sky_mat.sky_curve = _f("sky_curve", 0.25)
	sky_mat.sun_angle_max = _f("sky_sun_angle_max", 40.0)
	sky_mat.sun_curve = _f("sky_sun_curve", 0.12)
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = _f("ambient_energy", 0.95)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = _f("tonemap_exposure", 1.0)
	env.adjustment_enabled = true
	env.adjustment_contrast = _f("adjustment_contrast", 1.08)
	env.adjustment_saturation = _f("adjustment_saturation", 1.1)
	env.ssao_enabled = bool(_cfg.get("ssao_enabled", true))
	env.ssao_radius = _f("ssao_radius", 1.2)
	env.ssao_intensity = _f("ssao_intensity", 1.6)
	env.ssao_power = _f("ssao_power", 1.5)
	env.glow_enabled = bool(_cfg.get("glow_enabled", true))
	env.glow_intensity = _f("glow_intensity", 0.3)
	env.glow_bloom = _f("glow_bloom", 0.04)
	env.glow_hdr_threshold = _f("glow_hdr_threshold", 1.1)
	env.fog_enabled = true
	env.fog_light_color = _color("fog_color", "#f8e4cc")
	env.fog_density = _f("fog_density", 0.004)
	env.fog_sun_scatter = _f("fog_sun_scatter", 0.2)
	env.fog_sky_affect = _f("fog_sky_affect", 0.0)
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = _color("sun_color", "#ffe2bc")
	sun.light_energy = _f("sun_energy", 1.0)
	var rot: Array = _cfg.get("sun_rotation_degrees", [-26.0, 140.0, 0.0])
	sun.rotation_degrees = Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
	sun.shadow_enabled = true
	sun.shadow_opacity = _f("sun_shadow_opacity", 0.55)
	sun.shadow_blur = _f("sun_shadow_blur", 1.6)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = _f("sun_shadow_max_distance", 32.0)
	add_child(sun)


# --------------------------------------------------------------------------
# Terrain
# --------------------------------------------------------------------------

## 0 on plots, the entrance path and next to the fence (kept flat); 1 elsewhere.
func _terrain_mask(x: float, z: float) -> float:
	var m: float = 1.0
	var r0: float = _f("plot_flat_radius", 1.3)
	var r1: float = r0 + _f("plot_flat_blend", 1.4)
	var p := Vector2(x, z)
	for pt in _plot_pts:
		m = minf(m, smoothstep(r0, r1, p.distance_to(pt)))
	var pz: float = clampf((z - (_half.y - _path_length())) / 1.5, 0.0, 1.0)
	m = minf(m, lerpf(1.0, smoothstep(1.4, 2.6, absf(x)), pz))
	var fence_dist: float = minf(_half.x - absf(x), _half.y - absf(z))
	return minf(m, smoothstep(0.0, 2.5, fence_dist))


func _make_noise(seed_offset: int, frequency: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = int(_cfg.get("random_seed", 1)) + seed_offset
	n.frequency = frequency
	return n


## Subtle tiling grey noise texture multiplied into the ground albedo.
func _make_detail_texture() -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	noise.fractal_octaves = 3
	noise.seed = int(_cfg.get("random_seed", 1)) + 99
	var img: Image = noise.get_seamless_image(128, 128, false, false, 0.1, true)
	img.convert(Image.FORMAT_RGBA8)
	var contrast: float = _f("terrain_detail_contrast", 0.22)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var v: float = img.get_pixel(x, y).r
			var g: float = (1.0 - contrast) + contrast * v
			img.set_pixel(x, y, Color(g, g, g, 1.0))
	return ImageTexture.create_from_image(img)


func _build_terrain() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)

	# Far-away slab so no void shows beyond the terrain.
	var slab_size := Vector3(_half.x * 2.0 + GROUND_OVERSIZE, GROUND_THICKNESS, _half.y * 2.0 + GROUND_OVERSIZE)
	var slab := BoxMesh.new()
	slab.size = slab_size
	var slab_pos := Vector3(0.0, -GROUND_SINK - GROUND_THICKNESS * 0.5, 0.0)
	_add_mesh(ground, slab, str(_cfg.get("ground_color", "#9cc47a")), slab_pos)
	_add_box_collider(ground, slab_size, slab_pos)

	var n_var := _make_noise(1, 0.05)
	var n_dry := _make_noise(2, _f("patch_frequency", 0.16))
	var n_moss := _make_noise(3, _f("patch_frequency", 0.16))
	var n_clover := _make_noise(4, _f("patch_frequency", 0.16) * 1.4)
	var n_earth := _make_noise(5, _f("patch_frequency", 0.16) * 1.2)
	var lawn: Color = _color("ground_color", "#9cc47a")
	var lawn_light: Color = _color("ground_color_light", "#b2d18a")
	var dry: Color = _color("dry_color", "#c5b27a")
	var moss: Color = _color("moss_color", "#7aa862")
	var clover: Color = _color("clover_color", "#6aa66a")
	var earth: Color = _color("earth_color", "#a58a62")
	var amounts := Vector4(_f("dry_amount", 0.28), _f("moss_amount", 0.3), _f("clover_amount", 0.25), _f("earth_amount", 0.1))

	var cell: float = maxf(0.25, _f("terrain_cell", 0.5))
	var margin: float = _f("terrain_margin", 3.0)
	var ext := Vector2(_half.x + margin, _half.y + margin)
	var nx: int = int(ceil(ext.x * 2.0 / cell))
	var nz: int = int(ceil(ext.y * 2.0 / cell))
	var uv_tile: float = _f("terrain_uv_tile", 4.0)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(nz + 1):
		for i in range(nx + 1):
			var x: float = -ext.x + float(i) * cell
			var z: float = -ext.y + float(j) * cell
			var col: Color = lawn.lerp(lawn_light, clampf(n_var.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0))
			col = col.lerp(dry, smoothstep(1.0 - amounts.x, 1.0 - amounts.x + 0.25, n_dry.get_noise_2d(x, z) * 0.5 + 0.5) * 0.85)
			col = col.lerp(moss, smoothstep(1.0 - amounts.y, 1.0 - amounts.y + 0.25, n_moss.get_noise_2d(x, z) * 0.5 + 0.5) * 0.8)
			col = col.lerp(clover, smoothstep(1.0 - amounts.z, 1.0 - amounts.z + 0.25, n_clover.get_noise_2d(x, z) * 0.5 + 0.5) * 0.75)
			col = col.lerp(earth, smoothstep(1.0 - amounts.w, 1.0 - amounts.w + 0.15, n_earth.get_noise_2d(x, z) * 0.5 + 0.5) * 0.9)
			st.set_color(col)
			st.set_uv(Vector2(x, z) / uv_tile)
			st.add_vertex(Vector3(x, ground_height(x, z), z))
	for j in range(nz):
		for i in range(nx):
			var a: int = j * (nx + 1) + i
			var b: int = a + 1
			var c: int = a + nx + 1
			var d: int = c + 1
			# Godot front faces are clockwise: seen from above (+Y), a-b-c is clockwise.
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.albedo_texture = _make_detail_texture()
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	var terrain := MeshInstance3D.new()
	terrain.name = "Terrain"
	terrain.mesh = mesh
	terrain.material_override = mat
	ground.add_child(terrain)

	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	var col_shape := CollisionShape3D.new()
	var tri_shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	tri_shape.backface_collision = true
	col_shape.shape = tri_shape
	body.add_child(col_shape)
	ground.add_child(body)


# --------------------------------------------------------------------------
# Footpath: its own crisp, slightly irregular strip above the terrain
# --------------------------------------------------------------------------

func _path_center_x(z: float) -> float:
	return sin(z * 0.5) * _f("path_wobble", 0.2)


## Half-width of the path at z. side is -1 (left edge) or +1 (right edge); the path
## tapers to a rounded end and each edge wanders by path_edge_irregularity.
func _path_half_width(z: float, side: int) -> float:
	var end_z: float = _half.y - _path_length()
	var taper: float = clampf((z - end_z) / 1.2, 0.35, 1.0)
	var wander: float = _path_noise.get_noise_2d(z, 0.0 if side < 0 else 50.0)
	return _f("path_width", 0.75) * taper * (1.0 + _f("path_edge_irregularity", 0.1) * wander)


func _build_path() -> void:
	var end_z: float = _half.y - _path_length()
	var start_z: float = _half.y - 0.2
	var step: float = 0.25
	var rows: int = int(ceil((start_z - end_z) / step))
	var across: int = 3
	var lift: float = _f("path_lift", 0.03)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(rows + 1):
		var z: float = end_z + (start_z - end_z) * float(j) / float(rows)
		var cx: float = _path_center_x(z)
		var left: float = cx - _path_half_width(z, -1)
		var right: float = cx + _path_half_width(z, 1)
		for i in range(across + 1):
			var x: float = lerpf(left, right, float(i) / float(across))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x, ground_height(x, z) + lift, z))
	for j in range(rows):
		for i in range(across):
			var a: int = j * (across + 1) + i
			var b: int = a + 1
			var c: int = a + across + 1
			var d: int = c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	var mat := StandardMaterial3D.new()
	var sand: Color = _color("path_color", "#efd9a8")
	mat.albedo_color = sand
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# A little emission keeps the sand warm inside tree shadows instead of going grey.
	mat.emission_enabled = true
	mat.emission = sand
	mat.emission_energy_multiplier = _f("path_glow", 0.25)
	var path := MeshInstance3D.new()
	path.name = "Path"
	path.mesh = st.commit()
	path.material_override = mat
	add_child(path)


## Random point just outside the path edge (for edge tufts and pebbles).
func _path_edge_point(min_gap: float, max_gap: float) -> Vector2:
	var end_z: float = _half.y - _path_length()
	var z: float = _rng.randf_range(end_z + 0.3, _half.y - 0.6)
	var side: int = -1 if _rng.randf() < 0.5 else 1
	var edge: float = _path_center_x(z) + float(side) * _path_half_width(z, side)
	return Vector2(edge + float(side) * _rng.randf_range(min_gap, max_gap), z)


# --------------------------------------------------------------------------
# Fence
# --------------------------------------------------------------------------

func _build_fence() -> void:
	var fence := Node3D.new()
	fence.name = "Fence"
	add_child(fence)
	var hex: String = str(_cfg.get("fence_color", "#eadfc8"))
	var spacing: float = maxf(0.5, _f("fence_post_spacing", 1.6))
	var h: float = _f("fence_height", 0.9)
	var post := BoxMesh.new()
	post.size = Vector3(0.14, h, 0.14)
	var thickness: float = 0.1
	var lean_chance: float = _f("fence_lean_chance", 0.0)
	var lean_max: float = _f("fence_lean_max_degrees", 0.0)
	var broken_chance: float = _f("fence_broken_chance", 0.0)
	var broken_factor: float = _f("fence_broken_height_factor", 0.5)
	# [axis_is_x, fixed coordinate, side length]
	var sides: Array = [
		[true, -_half.y, _half.x * 2.0],
		[true, _half.y, _half.x * 2.0],
		[false, -_half.x, _half.y * 2.0],
		[false, _half.x, _half.y * 2.0],
	]
	for side: Array in sides:
		var along_x: bool = side[0]
		var fixed: float = side[1]
		var length: float = side[2]
		var count: int = maxi(1, int(round(length / spacing)))
		for i in range(count + 1):
			var t: float = -length * 0.5 + length * float(i) / float(count)
			var p := Vector3(t, h * 0.5, fixed) if along_x else Vector3(fixed, h * 0.5, t)
			var inst := _add_mesh(fence, post, hex, p)
			# Neglected fence: some posts lean, a few are broken short.
			var roll: float = _rng.randf()
			if roll < broken_chance:
				inst.scale.y = broken_factor
				inst.position.y = h * 0.5 * broken_factor
				inst.rotation = Vector3(_rng.randf_range(-0.2, 0.2), 0.0, _rng.randf_range(-0.2, 0.2))
			elif roll < broken_chance + lean_chance:
				var lean: float = deg_to_rad(lean_max)
				inst.rotation = Vector3(_rng.randf_range(-lean, lean), 0.0, _rng.randf_range(-lean, lean))
		for rail_y: float in [h * 0.35, h * 0.8]:
			var rail := BoxMesh.new()
			rail.size = Vector3(length, thickness, thickness) if along_x else Vector3(thickness, thickness, length)
			var rp := Vector3(0.0, rail_y, fixed) if along_x else Vector3(fixed, rail_y, 0.0)
			_add_mesh(fence, rail, hex, rp)
		var wall_size := Vector3(length, WALL_HEIGHT, 0.3) if along_x else Vector3(0.3, WALL_HEIGHT, length)
		var wall_pos := Vector3(0.0, WALL_HEIGHT * 0.5, fixed) if along_x else Vector3(fixed, WALL_HEIGHT * 0.5, 0.0)
		_add_box_collider(fence, wall_size, wall_pos)


# --------------------------------------------------------------------------
# Trees, bushes, stones
# --------------------------------------------------------------------------

## Adds a slightly squashed swaying foliage blob.
func _add_blob(parent: Node, radius: float, color: Color, pos: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.8
	mesh.radial_segments = 10
	mesh.rings = 5
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _foliage_material(color, mesh.height)
	inst.position = pos
	parent.add_child(inst)


func _build_props() -> void:
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)

	for t: Dictionary in _cfg.get("trees", []):
		var p: Array = t["pos"]
		var tx: float = float(p[0])
		var tz: float = float(p[1])
		var height: float = float(t.get("height", 4.0))
		var crown: float = float(t.get("crown", 2.0))
		var trunk_h: float = height * 0.55
		var tree := Node3D.new()
		tree.name = "Tree"
		tree.position = Vector3(tx, ground_height(tx, tz), tz)
		props.add_child(tree)

		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.12
		trunk.bottom_radius = 0.3
		trunk.height = trunk_h
		trunk.radial_segments = 8
		trunk.rings = 1
		var trunk_hex: String = str(t.get("trunk_color", "#8b6a4a"))
		_add_mesh(tree, trunk, trunk_hex, Vector3(0.0, trunk_h * 0.5, 0.0))
		# Two short branch stubs.
		var stub := CylinderMesh.new()
		stub.top_radius = 0.03
		stub.bottom_radius = 0.07
		stub.height = 0.9
		stub.radial_segments = 6
		stub.rings = 1
		for k in range(2):
			var pivot := Node3D.new()
			pivot.position = Vector3(0.0, trunk_h * (0.55 + 0.18 * float(k)), 0.0)
			pivot.rotation.y = _rng.randf_range(0.0, TAU)
			tree.add_child(pivot)
			var tilt: float = _rng.randf_range(0.7, 1.1)
			var stub_inst := _add_mesh(pivot, stub, trunk_hex, Vector3(-sin(tilt) * 0.45, cos(tilt) * 0.45, 0.0))
			stub_inst.rotation.z = tilt

		var crown_colors: Array = t.get("crown_colors", ["#79b872"])
		var blobs: int = maxi(1, int(t.get("crown_blobs", 3)))
		for b in range(blobs):
			var color := Color.html(str(crown_colors[b % crown_colors.size()]))
			if b == 0:
				_add_blob(tree, crown, color, Vector3(0.0, trunk_h + crown * 0.5, 0.0))
			else:
				var angle: float = _rng.randf_range(0.0, TAU)
				var dist: float = crown * _rng.randf_range(0.5, 0.8)
				var offset := Vector3(cos(angle) * dist, crown * _rng.randf_range(0.0, 0.55), sin(angle) * dist)
				_add_blob(tree, crown * _rng.randf_range(0.65, 0.85), color, Vector3(0.0, trunk_h, 0.0) + offset)
		_add_box_collider(tree, Vector3(0.5, trunk_h, 0.5), Vector3(0.0, trunk_h * 0.5, 0.0))

	for b: Dictionary in _cfg.get("bushes", []):
		var bp: Array = b["pos"]
		var bx: float = float(bp[0])
		var bz: float = float(bp[1])
		var r: float = float(b.get("radius", 0.8))
		var base := Color.html(str(b.get("color", "#6fae6b")))
		var bush := Node3D.new()
		bush.name = "Bush"
		bush.position = Vector3(bx, ground_height(bx, bz), bz)
		props.add_child(bush)
		_add_blob(bush, r * 0.8, base, Vector3(0.0, r * 0.4, 0.0))
		for k in range(2):
			var angle: float = _rng.randf_range(0.0, TAU)
			var shade: Color = base.lightened(0.12) if k == 0 else base.darkened(0.12)
			_add_blob(bush, r * _rng.randf_range(0.5, 0.65), shade,
				Vector3(cos(angle) * r * 0.55, r * 0.3, sin(angle) * r * 0.55))

	for s: Dictionary in _cfg.get("stones", []):
		var sp: Array = s["pos"]
		var sx: float = float(sp[0])
		var sz: float = float(sp[1])
		var sr: float = float(s.get("radius", 0.3))
		var stone := SphereMesh.new()
		stone.radius = sr
		stone.height = sr * 1.2
		stone.radial_segments = 6
		stone.rings = 3
		var inst := _add_mesh(props, stone, str(s.get("color", "#c4bfb4")), Vector3(sx, ground_height(sx, sz) + sr * 0.3, sz))
		inst.rotation.y = _rng.randf_range(0.0, TAU)


# --------------------------------------------------------------------------
# Grass, reeds, weeds (one MultiMesh, wind-swayed)
# --------------------------------------------------------------------------

## True when (x, z) is too close to a planting spot or the entrance path to hold grass.
func _is_reserved(x: float, z: float) -> bool:
	var clear: float = _f("plot_radius", 0.5) + 0.8
	for pt in _plot_pts:
		if Vector2(x, z).distance_to(pt) < clear:
			return true
	return absf(x - _path_center_x(z)) < _f("path_width", 0.75) + 0.45 and z > _half.y - _path_length()


func _near_plot(x: float, z: float) -> bool:
	for pt in _plot_pts:
		if Vector2(x, z).distance_to(pt) < _f("plot_radius", 0.5) + 0.5:
			return true
	return false


func _pick_color(palette: Array) -> Color:
	return Color.html(str(palette[_rng.randi() % palette.size()]))


func _build_grass() -> void:
	var blade_h: float = _f("grass_blade_height", 0.7)
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 0.05
	blade.height = blade_h
	blade.radial_segments = 3
	blade.rings = 1
	blade.cap_bottom = false
	var mat := ShaderMaterial.new()
	mat.shader = _wind_shader
	_apply_wind_params(mat, _f("grass_wind_strength", 0.22))
	mat.set_shader_parameter("use_instance_color", true)
	mat.set_shader_parameter("grass_normals", true)
	mat.set_shader_parameter("height_offset", blade_h * 0.5)
	mat.set_shader_parameter("height_range", blade_h)
	mat.set_shader_parameter("height_power", 1.6)
	mat.set_shader_parameter("tip_brighten", 0.35)

	var palette: Array = _cfg.get("grass_palette", ["#7fb56a"])
	var reed_palette: Array = _cfg.get("reed_palette", palette)
	var per_tuft: int = int(_cfg.get("grass_tuft_blades", 5))
	var density: float = _f("grass_density", 1.0)

	# Each tuft: [position, height scale, max tilt (rad), colour]
	var tufts: Array = []
	var limit := Vector2(_half.x - 0.5, _half.y - 0.5)

	for patch: Dictionary in _cfg.get("grass_patches", []):
		var pp: Array = patch["pos"]
		var radius: float = float(patch.get("radius", 2.0))
		for i in range(int(round(float(patch.get("tufts", 10)) * density))):
			var angle: float = _rng.randf_range(0.0, TAU)
			var dist: float = radius * sqrt(_rng.randf())
			var x: float = float(pp[0]) + cos(angle) * dist
			var z: float = float(pp[1]) + sin(angle) * dist
			if _is_reserved(x, z) or absf(x) > limit.x or absf(z) > limit.y:
				continue
			tufts.append([Vector3(x, ground_height(x, z), z), _rng.randf_range(0.8, 1.7), 0.3, _pick_color(palette)])

	var meadow_range: Array = _cfg.get("meadow_height_scale", [0.45, 0.9])
	for i in range(int(_cfg.get("meadow_tufts", 0))):
		var mx: float = _rng.randf_range(-limit.x, limit.x)
		var mz: float = _rng.randf_range(-limit.y, limit.y)
		if _is_reserved(mx, mz):
			continue
		tufts.append([Vector3(mx, ground_height(mx, mz), mz),
			_rng.randf_range(float(meadow_range[0]), float(meadow_range[1])), 0.35, _pick_color(palette)])

	# Tall reeds in a band along the fence.
	var reed_range: Array = _cfg.get("reed_height_scale", [2.0, 2.8])
	for i in range(int(_cfg.get("reed_tufts", 0))):
		var inset: float = _rng.randf_range(0.2, 1.3)
		var side: int = _rng.randi() % 4
		var along: float = _rng.randf_range(-1.0, 1.0)
		var rx: float
		var rz: float
		if side == 0:
			rx = along * (_half.x - 0.3)
			rz = -_half.y + inset
		elif side == 1:
			rx = along * (_half.x - 0.3)
			rz = _half.y - inset
		elif side == 2:
			rx = -_half.x + inset
			rz = along * (_half.y - 0.3)
		else:
			rx = _half.x - inset
			rz = along * (_half.y - 0.3)
		if _is_reserved(rx, rz):
			continue
		tufts.append([Vector3(rx, ground_height(rx, rz), rz),
			_rng.randf_range(float(reed_range[0]), float(reed_range[1])), 0.12, _pick_color(reed_palette)])

	# Small tufts hugging the path edges.
	for i in range(int(_cfg.get("path_edge_tufts", 0))):
		var ep: Vector2 = _path_edge_point(0.05, 0.45)
		if _near_plot(ep.x, ep.y):
			continue
		tufts.append([Vector3(ep.x, ground_height(ep.x, ep.y), ep.y), _rng.randf_range(0.45, 0.95), 0.3, _pick_color(palette)])

	var weed_scale: float = _f("weed_scale", 0.45)
	var weeds_made: int = 0
	var attempts: int = 0
	var weed_target: int = int(_cfg.get("weed_count", 0))
	while weeds_made < weed_target and attempts < weed_target * 20:
		attempts += 1
		var wx: float = _rng.randf_range(-_half.x + 0.6, _half.x - 0.6)
		var wz: float = _rng.randf_range(-_half.y + 0.6, _half.y - 0.6)
		if _is_reserved(wx, wz):
			continue
		tufts.append([Vector3(wx, ground_height(wx, wz), wz), weed_scale * _rng.randf_range(0.8, 1.3), 0.4, _pick_color(palette)])
		weeds_made += 1

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for tuft: Array in tufts:
		var base: Vector3 = tuft[0]
		var hs: float = tuft[1]
		var tilt: float = tuft[2]
		var tuft_color: Color = tuft[3]
		for b in range(per_tuft):
			var blade_basis := Basis.from_euler(Vector3(
				_rng.randf_range(-tilt, tilt), _rng.randf_range(0.0, TAU), _rng.randf_range(-tilt, tilt)))
			blade_basis = blade_basis * Basis.from_scale(Vector3(
				_rng.randf_range(0.8, 1.4), hs * _rng.randf_range(0.8, 1.2), _rng.randf_range(0.8, 1.4)))
			var origin: Vector3 = base + Vector3(_rng.randf_range(-0.12, 0.12), 0.0, _rng.randf_range(-0.12, 0.12))
			origin += blade_basis * Vector3(0.0, blade_h * 0.5, 0.0)
			transforms.append(Transform3D(blade_basis, origin))
			colors.append(tuft_color.darkened(_rng.randf_range(0.0, 0.15)))
	var grass := MultiMeshInstance3D.new()
	grass.name = "Grass"
	grass.multimesh = _make_multimesh(blade, transforms, colors)
	grass.material_override = mat
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)


# --------------------------------------------------------------------------
# Pebbles and fallen leaves (two small MultiMeshes)
# --------------------------------------------------------------------------

func _build_litter() -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0

	var pebble := SphereMesh.new()
	pebble.radius = 0.5
	pebble.height = 0.6
	pebble.radial_segments = 6
	pebble.rings = 3
	var leaf := BoxMesh.new()
	leaf.size = Vector3(0.14, 0.012, 0.08)

	var pebble_palette: Array = _cfg.get("pebble_palette", ["#b9b4aa"])
	var leaf_palette: Array = _cfg.get("leaf_palette", ["#c98a4a"])
	var pebble_t: Array[Transform3D] = []
	var pebble_c: Array[Color] = []
	var leaf_t: Array[Transform3D] = []
	var leaf_c: Array[Color] = []
	var span := Vector2(_half.x - 0.6, _half.y - 0.6)
	for kind in range(2):
		var target: int = int(_cfg.get("pebble_count" if kind == 0 else "leaf_count", 0))
		var made: int = 0
		var attempts: int = 0
		while made < target and attempts < target * 20:
			attempts += 1
			var x: float = _rng.randf_range(-span.x, span.x)
			var z: float = _rng.randf_range(-span.y, span.y)
			if _is_reserved(x, z):
				continue
			var y: float = ground_height(x, z)
			var yaw := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			if kind == 0:
				var s: float = _rng.randf_range(0.1, 0.24)
				pebble_t.append(Transform3D(yaw * Basis.from_scale(Vector3(s, s * 0.8, s * _rng.randf_range(0.7, 1.1))), Vector3(x, y + s * 0.15, z)))
				pebble_c.append(_pick_color(pebble_palette))
			else:
				leaf_t.append(Transform3D(yaw, Vector3(x, y + 0.012, z)))
				leaf_c.append(_pick_color(leaf_palette))
			made += 1

	for i in range(int(_cfg.get("path_edge_pebbles", 0))):
		var pe: Vector2 = _path_edge_point(0.02, 0.35)
		if _near_plot(pe.x, pe.y):
			continue
		var ps: float = _rng.randf_range(0.1, 0.2)
		var pyaw := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
		pebble_t.append(Transform3D(pyaw * Basis.from_scale(Vector3(ps, ps * 0.8, ps)), Vector3(pe.x, ground_height(pe.x, pe.y) + ps * 0.15, pe.y)))
		pebble_c.append(_pick_color(pebble_palette))

	for kind in range(2):
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Pebbles" if kind == 0 else "FallenLeaves"
		mmi.multimesh = _make_multimesh(
			pebble if kind == 0 else leaf,
			pebble_t if kind == 0 else leaf_t,
			pebble_c if kind == 0 else leaf_c)
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


# --------------------------------------------------------------------------
# Clouds: several overlapping soft puffs per cloud, drifting slowly
# --------------------------------------------------------------------------

func _build_clouds() -> void:
	var mat := StandardMaterial3D.new()
	var cloud_color: Color = _color("cloud_color", "#fff6ea")
	mat.albedo_color = cloud_color
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = cloud_color
	mat.emission_energy_multiplier = 0.55
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var clouds := Node3D.new()
	clouds.name = "Clouds"
	add_child(clouds)
	var puffs: int = maxi(2, int(_cfg.get("cloud_puffs", 6)))
	for c: Dictionary in _cfg.get("clouds", []):
		var cp: Array = c["pos"]
		var cs: Array = c["scale"]
		var sx: float = float(cs[0])
		var sy: float = float(cs[1])
		var sz: float = float(cs[2])
		var cloud := Node3D.new()
		cloud.position = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))
		clouds.add_child(cloud)
		for i in range(puffs):
			var t: float = float(i) / float(puffs - 1)
			var arch: float = 1.0 - absf(t * 2.0 - 1.0)
			var puff := MeshInstance3D.new()
			puff.mesh = mesh
			puff.material_override = mat
			puff.position = Vector3(
				lerpf(-sx, sx, t) + _rng.randf_range(-0.8, 0.8),
				sy * arch * _rng.randf_range(0.2, 0.8),
				_rng.randf_range(-sz * 0.3, sz * 0.3))
			puff.scale = Vector3(sz * _rng.randf_range(0.9, 1.4), sy * _rng.randf_range(1.0, 1.6), sz * _rng.randf_range(0.8, 1.2))
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(puff)
		_clouds.append(cloud)


# --------------------------------------------------------------------------
# Planting spots, player
# --------------------------------------------------------------------------

func _build_plots() -> int:
	var plots := Node3D.new()
	plots.name = "Plots"
	add_child(plots)
	var radius: float = _f("plot_radius", 0.5)
	var soil := CylinderMesh.new()
	soil.top_radius = radius
	soil.bottom_radius = radius
	soil.height = 0.1
	soil.radial_segments = 14
	soil.rings = 1
	var ring := TorusMesh.new()
	ring.inner_radius = radius
	ring.outer_radius = radius + 0.1
	ring.rings = 14
	ring.ring_segments = 4
	var soil_hex: String = str(_cfg.get("plot_color", "#7a5238"))
	var ring_hex: String = str(_cfg.get("plot_marker_color", "#f4c9d4"))
	var index: int = 0
	for pos: Array in _cfg.get("plot_positions", []):
		var px: float = float(pos[0])
		var pz: float = float(pos[1])
		var plot := Node3D.new()
		plot.name = "FlowerPlot%d" % (index + 1)
		plot.position = Vector3(px, ground_height(px, pz), pz)
		plot.set_meta(&"plot_index", index)
		plot.add_to_group(PLOTS_GROUP)
		plots.add_child(plot)
		_add_mesh(plot, soil, soil_hex, Vector3(0.0, 0.05, 0.0))
		var marker := _add_mesh(plot, ring, ring_hex, Vector3(0.0, 0.08, 0.0))
		marker.scale = Vector3(1.0, 0.5, 1.0)
		index += 1
	return index


func _build_player(player_cfg: Dictionary) -> void:
	var margin: float = _f("player_margin", 0.8)
	var player := GardenPlayer.new()
	player.name = "Player"
	player.configure(
		player_cfg,
		Vector2(-_half.x + margin, -_half.y + margin),
		Vector2(_half.x - margin, _half.y - margin))
	add_child(player)
