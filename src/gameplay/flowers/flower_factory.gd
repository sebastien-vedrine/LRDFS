class_name FlowerFactory
extends RefCounted
## Builds the six procedural flower looks from data (Story 002,
## design/game-brief.md). Everything is primitives or one tiny generated mesh;
## every look stays well under ~60 mesh instances.
##
## Looks (the "look" key of assets/data/flowers.json): sunflower, wild_rose,
## forget_me_not, lily_valley, jericho. Colours/sizes come from the "params"
## dictionary of each flower; the fallbacks below only guard against a missing key.
##
## Orientation convention: the flowers face +Z (towards the player's entrance).
## Pivot nodes carry the open pose; [FlowerVisual] animates from the closed pose.

## Stem growth ends here (bloom progress 0..1); leaves and heads follow.
const STEM_END: float = 0.45
const HEAD_START: float = 0.5


## Builds the flower for [param flower] (one entry of the "flowers" list).
## [param settings] is the "settings" block (sparkle tuning). Returned at bloom progress 0.
static func build(flower: Dictionary, settings: Dictionary) -> FlowerVisual:
	var visual := FlowerVisual.new()
	visual.name = "Flower_%s" % str(flower.get("id", "unknown"))
	var p: Dictionary = flower.get("params", {})
	var sparkle: Array = _sparkle_spot(str(flower.get("look", "")), p)
	match str(flower.get("look", "")):
		"sunflower":
			_build_sunflower(visual, p)
		"wild_rose":
			_build_wild_rose(visual, p)
		"forget_me_not":
			_build_forget_me_not(visual, p)
		"lily_valley":
			_build_lily_valley(visual, p)
		"jericho":
			_build_jericho(visual, p)
		_:
			push_warning("FlowerFactory: unknown look '%s'" % str(flower.get("look", "")))
	var origin: Vector3 = sparkle[0]
	var radius: float = sparkle[1]
	visual.setup_sparkles(_color(flower, "sparkle_color", "#fff2a8"), settings, origin, radius)
	visual.set_progress(0.0)
	return visual


# --------------------------------------------------------------------------
# Looks
# --------------------------------------------------------------------------

static func _sparkle_spot(look: String, p: Dictionary) -> Array:
	match look:
		"sunflower":
			var h: float = _num(p, "stem_height", 1.1)
			var r: float = _num(p, "head_radius", 0.3)
			return [Vector3(0.0, h + r * 0.3, r * 0.6), r]
		"wild_rose":
			return [Vector3(0.0, _num(p, "stem_height", 0.78) + 0.04, 0.05), _num(p, "bloom_radius", 0.16)]
		"forget_me_not":
			return [Vector3(0.0, _num(p, "stem_height", 0.6) * 0.8, 0.0), _num(p, "branch_length", 0.17)]
		"lily_valley":
			return [Vector3(0.12, _num(p, "stem_length", 0.62) * 0.7, 0.0), 0.15]
		_:
			return [Vector3(0.0, _num(p, "bloom_height", 0.5), 0.0), _num(p, "bloom_radius", 0.17)]


static func _build_sunflower(v: FlowerVisual, p: Dictionary) -> void:
	var h: float = _num(p, "stem_height", 1.1)
	var hr: float = _num(p, "head_radius", 0.3)
	var petals: int = int(_num(p, "petal_count", 14.0))
	_add_stem(v, h, _num(p, "stem_radius", 0.028), _color(p, "stem_color", "#6aa14f"))

	# Three broad leaves unfolding from the stem.
	var leaf_mat := _mat(_color(p, "leaf_color", "#5c9a45"), 0.0, true)
	var leaf_len: float = h * 0.24
	var leaf_heights: Array[float] = [0.26, 0.48, 0.68]
	var leaf_yaws: Array[float] = [25.0, 150.0, 268.0]
	for i in range(leaf_heights.size()):
		var pivot := _pivot(v, Vector3(0.0, h * leaf_heights[i], 0.0), Vector3(0.0, leaf_yaws[i], -14.0))
		_add(pivot, _sphere(), leaf_mat, Vector3(leaf_len * 0.5, 0.0, 0.0), Vector3.ZERO, Vector3(leaf_len, 0.015, leaf_len * 0.55))
		v.add_unfold(pivot, 0.18 + 0.08 * float(i), 0.55 + 0.05 * float(i), Vector3(0.0, leaf_yaws[i], 82.0))

	# Head: green calyx, two petal rings (cupped, then they flatten), seed dome.
	var head := _pivot(v, Vector3(0.0, h, 0.0), Vector3(_num(p, "head_tilt_degrees", 66.0), 0.0, 0.0))
	var calyx := _add(head, _sphere(), _mat(_color(p, "leaf_color", "#5c9a45")), Vector3(0.0, -0.03 * hr, 0.0), Vector3.ZERO, Vector3(hr * 0.9, hr * 0.35, hr * 0.9))
	v.add_uniform(calyx, HEAD_START - 0.05, HEAD_START + 0.2)
	var outer_mat := _mat(_color(p, "petal_color", "#ffcf2e"), 0.12, true)
	var inner_mat := _mat(_color(p, "petal_inner_color", "#f7a81b"), 0.1, true)
	var outer := _add(head, _petal_disc(petals, hr * 0.32, hr, hr * 0.22, 1.6, 6), outer_mat, Vector3.ZERO)
	v.add_pop(outer, HEAD_START + 0.02, HEAD_START + 0.38, Vector3(0.15, 2.4, 0.15))
	var inner := _add(head, _petal_disc(petals, hr * 0.3, hr * 0.78, hr * 0.2, 1.6, 6), inner_mat, Vector3(0.0, 0.02 * hr, 0.0), Vector3(0.0, 180.0 / float(petals), 0.0))
	v.add_pop(inner, HEAD_START + 0.1, HEAD_START + 0.44, Vector3(0.15, 2.4, 0.15))
	var dome := _add(head, _sphere(), _mat(_color(p, "centre_color", "#5b3a1e")), Vector3(0.0, 0.03 * hr, 0.0), Vector3.ZERO, Vector3(hr * 0.8, hr * 0.32, hr * 0.8))
	v.add_uniform(dome, HEAD_START + 0.05, HEAD_START + 0.3)
	if p.has("gold_ring_color"):
		var gold := _mat(_color(p, "gold_ring_color", "#ffd24a"), 0.35)
		gold.metallic = 0.85
		gold.roughness = 0.3
		var ring := TorusMesh.new()
		ring.inner_radius = hr * 0.38
		ring.outer_radius = hr * 0.46
		ring.rings = 16
		ring.ring_segments = 5
		var ring_node := _add(head, ring, gold, Vector3(0.0, 0.07 * hr, 0.0))
		v.add_uniform(ring_node, HEAD_START + 0.3, HEAD_START + 0.5)


static func _build_wild_rose(v: FlowerVisual, p: Dictionary) -> void:
	var h: float = _num(p, "stem_height", 0.78)
	var r: float = _num(p, "bloom_radius", 0.16)
	var stem_r: float = _num(p, "stem_radius", 0.014)
	_add_stem(v, h, stem_r, _color(p, "stem_color", "#6f8a3f"))

	# Thorns: small cones alternating sides along the stem.
	var thorn_mat := _mat(_color(p, "thorn_color", "#8a4a3a"))
	var thorn_mesh := CylinderMesh.new()
	thorn_mesh.top_radius = 0.0
	thorn_mesh.bottom_radius = stem_r * 0.9
	thorn_mesh.height = stem_r * 3.4
	thorn_mesh.radial_segments = 5
	thorn_mesh.rings = 1
	var thorns: int = int(_num(p, "thorn_count", 7.0))
	for i in range(thorns):
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var y: float = h * lerpf(0.12, 0.8, float(i) / float(maxi(thorns - 1, 1)))
		var thorn := _add(v, thorn_mesh, thorn_mat, Vector3(side * stem_r * 1.3, y, 0.0), Vector3(0.0, 0.0, -side * 65.0))
		thorn.rotation_degrees.y = float(i) * 55.0
		v.add_uniform(thorn, 0.1 + 0.4 * (y / h) * 0.6, 0.35 + 0.3 * (y / h))

	# Small oval leaves.
	var leaf_mat := _mat(_color(p, "leaf_color", "#5f9448"), 0.0, true)
	var leaf_len: float = h * 0.17
	for i in range(5):
		var yaw: float = 40.0 + 137.0 * float(i)
		var pivot := _pivot(v, Vector3(0.0, h * (0.22 + 0.12 * float(i)), 0.0), Vector3(0.0, yaw, -10.0))
		_add(pivot, _sphere(), leaf_mat, Vector3(leaf_len * 0.5, 0.0, 0.0), Vector3.ZERO, Vector3(leaf_len, 0.01, leaf_len * 0.55))
		v.add_unfold(pivot, 0.2 + 0.05 * float(i), 0.55 + 0.04 * float(i), Vector3(0.0, yaw, 80.0))

	# Bloom: five pale petals around a yellow centre.
	var head := _pivot(v, Vector3(0.0, h, 0.0), Vector3(_num(p, "bloom_tilt_degrees", 52.0), 0.0, 0.0))
	var calyx := _add(head, _sphere(), _mat(_color(p, "leaf_color", "#5f9448")), Vector3(0.0, -0.04, 0.0), Vector3.ZERO, Vector3(r * 0.45, r * 0.4, r * 0.45))
	v.add_uniform(calyx, HEAD_START - 0.05, HEAD_START + 0.15)
	var petal_mat := _mat(_color(p, "petal_color", "#f9d3dd"), 0.1, true)
	var petal_mesh := _sphere()
	for i in range(5):
		var yaw: float = 72.0 * float(i)
		var pivot := _pivot(head, Vector3.ZERO, Vector3(0.0, yaw, 14.0))
		_add(pivot, petal_mesh, petal_mat, Vector3(r * 0.58, 0.0, 0.0), Vector3.ZERO, Vector3(r * 1.05, r * 0.12, r * 0.95))
		v.add_unfold(pivot, HEAD_START + 0.03 * float(i), HEAD_START + 0.32 + 0.03 * float(i), Vector3(0.0, yaw, 80.0))
	var centre_c: Color = _color(p, "centre_color", "#ffd84a")
	var centre := _add(head, _sphere(), _mat(centre_c, 0.3), Vector3(0.0, 0.01, 0.0), Vector3.ZERO, Vector3(r * 0.42, r * 0.22, r * 0.42))
	v.add_uniform(centre, HEAD_START + 0.2, HEAD_START + 0.42)
	var stamens := TorusMesh.new()
	stamens.inner_radius = r * 0.2
	stamens.outer_radius = r * 0.32
	stamens.rings = 12
	stamens.ring_segments = 4
	var stamen_node := _add(head, stamens, _mat(centre_c.lightened(0.15), 0.3), Vector3(0.0, 0.015, 0.0), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
	v.add_uniform(stamen_node, HEAD_START + 0.3, HEAD_START + 0.5)


static func _build_forget_me_not(v: FlowerVisual, p: Dictionary) -> void:
	var h: float = _num(p, "stem_height", 0.6)
	var branches: int = int(_num(p, "branch_count", 9.0))
	var blen: float = _num(p, "branch_length", 0.17)
	var fr: float = _num(p, "flower_radius", 0.05)
	var stem_r: float = _num(p, "stem_radius", 0.012)
	var stem_color: Color = _color(p, "stem_color", "#6fa05a")
	_add_stem(v, h, stem_r, stem_color)

	var branch_mesh := CylinderMesh.new()
	branch_mesh.top_radius = stem_r * 0.4
	branch_mesh.bottom_radius = stem_r * 0.6
	branch_mesh.height = blen
	branch_mesh.radial_segments = 4
	branch_mesh.rings = 1
	var branch_mat := _mat(stem_color)
	var petal_mat := _mat(_color(p, "petal_color", "#8ecbff"), 0.25, true)
	var centre_mat := _mat(_color(p, "centre_color", "#ffe27a"), 0.5)
	var disc: ArrayMesh = _petal_disc(5, fr * 0.3, fr, fr * 0.15, 0.7, 5)
	var centre_mesh := _sphere()
	var branch_tilt: float = 52.0

	for i in range(branches):
		var yaw: float = 137.5 * float(i)
		var y: float = h * lerpf(0.3, 0.92, float(i) / float(maxi(branches - 1, 1)))
		var pivot := _pivot(v, Vector3(0.0, y, 0.0), Vector3(0.0, yaw, branch_tilt))
		_add(pivot, branch_mesh, branch_mat, Vector3(blen * 0.5, 0.0, 0.0), Vector3(0.0, 0.0, -90.0))
		v.add_unfold(pivot, 0.2 + 0.03 * float(i), 0.5 + 0.03 * float(i), Vector3(0.0, yaw, 84.0))
		var start: float = 0.5 + 0.027 * float(i)
		_tiny_flower(v, pivot, Vector3(blen, 0.0, 0.0), Vector3(0.0, 0.0, -(branch_tilt + 18.0)), disc, petal_mat, centre_mesh, centre_mat, fr, start, minf(start + 0.23, 1.0))
	# Crowning flower on the main stem.
	_tiny_flower(v, v, Vector3(0.0, h, 0.0), Vector3(30.0, 0.0, 0.0), disc, petal_mat, centre_mesh, centre_mat, fr * 1.15, 0.72, 1.0)

	var leaf_mat := _mat(_color(p, "leaf_color", "#5f9a50"), 0.0, true)
	for i in range(3):
		var yaw: float = 60.0 + 125.0 * float(i)
		var pivot := _pivot(v, Vector3(0.0, h * (0.08 + 0.1 * float(i)), 0.0), Vector3(0.0, yaw, 30.0))
		_add(pivot, _sphere(), leaf_mat, Vector3(0.06, 0.0, 0.0), Vector3.ZERO, Vector3(0.12, 0.008, 0.035))
		v.add_unfold(pivot, 0.15 + 0.07 * float(i), 0.5 + 0.05 * float(i), Vector3(0.0, yaw, 85.0))


static func _tiny_flower(v: FlowerVisual, parent: Node3D, pos: Vector3, rot_deg: Vector3, disc: Mesh, petal_mat: Material, centre_mesh: Mesh, centre_mat: Material, radius: float, start: float, end: float) -> void:
	var flower := _add(parent, disc, petal_mat, pos, rot_deg)
	_add(flower, centre_mesh, centre_mat, Vector3(0.0, radius * 0.06, 0.0), Vector3.ZERO, Vector3(radius * 0.5, radius * 0.3, radius * 0.5))
	v.add_uniform(flower, start, end)


static func _build_lily_valley(v: FlowerVisual, p: Dictionary) -> void:
	var length: float = _num(p, "stem_length", 0.62)
	var stem_r: float = _num(p, "stem_radius", 0.013)
	var arch: float = _num(p, "arch_degrees", 110.0)
	var bells: int = int(_num(p, "bell_count", 7.0))
	var bell_size: float = _num(p, "bell_size", 0.065)
	var stem_mat := _mat(_color(p, "stem_color", "#6fa05a"))

	# Arching stem: a chain of short cylinders whose heading bends towards +X.
	var segments: int = 8
	var seg_len: float = length / float(segments)
	var arch_group := Node3D.new()
	arch_group.name = "Arch"
	v.add_child(arch_group)
	var seg_mesh := CylinderMesh.new()
	seg_mesh.top_radius = stem_r * 0.7
	seg_mesh.bottom_radius = stem_r
	seg_mesh.height = seg_len * 1.08
	seg_mesh.radial_segments = 5
	seg_mesh.rings = 1
	var points: Array[Vector3] = [Vector3.ZERO]
	for i in range(segments):
		var heading: float = deg_to_rad(lerpf(4.0, arch, pow(float(i) / float(segments - 1), 1.6)))
		var dir := Vector3(sin(heading), cos(heading), 0.0)
		var from: Vector3 = points[i]
		_add(arch_group, seg_mesh, stem_mat, from + dir * seg_len * 0.5, Vector3(0.0, 0.0, -rad_to_deg(heading)))
		points.append(from + dir * seg_len)
	v.add_uniform(arch_group, 0.0, STEM_END)

	# White bells hanging from the bent part of the stem.
	var bell_mat := _mat(_color(p, "bell_color", "#fffdf6"), 0.15)
	var lip_mat := _mat(_color(p, "bell_lip_color", "#f1ecd8"), 0.1, true)
	var pedicel_mesh := CylinderMesh.new()
	pedicel_mesh.top_radius = stem_r * 0.3
	pedicel_mesh.bottom_radius = stem_r * 0.3
	pedicel_mesh.height = bell_size * 0.9
	pedicel_mesh.radial_segments = 3
	pedicel_mesh.rings = 1
	var sphere := _sphere()
	for k in range(bells):
		var t: float = lerpf(0.4, 1.0, float(k) / float(maxi(bells - 1, 1)))
		var idx: int = clampi(int(t * float(segments)), 0, segments)
		var side: float = 1.0 if k % 2 == 0 else -1.0
		var holder := Node3D.new()
		holder.position = points[idx] + Vector3(0.012, -bell_size * 1.2, side * 0.018)
		v.add_child(holder)
		_add(holder, pedicel_mesh, stem_mat, Vector3(-0.004, bell_size * 0.75, -side * 0.009), Vector3(0.0, 0.0, 10.0))
		_add(holder, sphere, bell_mat, Vector3.ZERO, Vector3.ZERO, Vector3(bell_size, bell_size * 0.9, bell_size))
		_add(holder, sphere, lip_mat, Vector3(0.0, -bell_size * 0.38, 0.0), Vector3.ZERO, Vector3(bell_size * 1.25, bell_size * 0.2, bell_size * 1.25))
		var start: float = 0.5 + 0.06 * float(k)
		v.add_uniform(holder, start, minf(start + 0.2, 1.0))

	# Two broad ribbed leaves standing at the base.
	var leaf_mat := _mat(_color(p, "leaf_color", "#4f9250"), 0.0, true)
	var leaf_len: float = _num(p, "leaf_length", 0.42)
	var leaf_yaws: Array[float] = [80.0, -100.0]
	for i in range(2):
		var pivot := _pivot(v, Vector3(0.0, 0.0, 0.0), Vector3(0.0, leaf_yaws[i], 58.0))
		_add(pivot, sphere, leaf_mat, Vector3(leaf_len * 0.5, 0.0, 0.0), Vector3.ZERO, Vector3(leaf_len, 0.012, leaf_len * 0.34))
		v.add_unfold(pivot, 0.1 + 0.1 * float(i), 0.5 + 0.05 * float(i), Vector3(0.0, leaf_yaws[i], 88.0))


static func _build_jericho(v: FlowerVisual, p: Dictionary) -> void:
	var count: int = int(_num(p, "frond_count", 12.0))
	var flen: float = _num(p, "frond_length", 0.3)
	var fwid: float = _num(p, "frond_width", 0.075)
	var frond_mat := _mat(_color(p, "frond_color", "#8fa58a"), 0.0, true)
	var tip_mat := _mat(_color(p, "frond_tip_color", "#aabfa0"), 0.0, true)
	var sphere := _sphere()
	var bloom_h: float = _num(p, "bloom_height", 0.5)
	var tilt0: float = _num(p, "frond_tilt_degrees", 42.0)
	var tilt_step: float = _num(p, "frond_tilt_step", 26.0)
	# Slim stem lifting the pale bloom above the cup of fronds.
	_add_stem(v, bloom_h, _num(p, "stem_radius", 0.022), _color(p, "stem_color", "#8fa58a"))
	for i in range(count):
		var ring: int = i % 2
		var yaw: float = 360.0 / float(count) * float(i) + 15.0 * float(ring)
		var open_tilt: float = tilt0 + tilt_step * float(ring)
		var pivot := _pivot(v, Vector3(0.0, 0.035, 0.0), Vector3(0.0, yaw, open_tilt))
		_add(pivot, sphere, frond_mat, Vector3(flen * 0.5, 0.0, 0.0), Vector3.ZERO, Vector3(flen, 0.012, fwid * (1.0 - 0.2 * float(ring))))
		var tip := _pivot(pivot, Vector3(flen * 0.92, 0.0, 0.0), Vector3(0.0, 0.0, 24.0))
		_add(tip, sphere, tip_mat, Vector3(flen * 0.18, 0.0, 0.0), Vector3.ZERO, Vector3(flen * 0.38, 0.01, fwid * 0.6))
		v.add_unfold(pivot, 0.05 + 0.025 * float(i), 0.6 + 0.02 * float(i), Vector3(0.0, yaw, 80.0))

	# Small pale bloom in the heart of the rosette.
	var br: float = _num(p, "bloom_radius", 0.09)
	var holder := Node3D.new()
	holder.position = Vector3(0.0, bloom_h, 0.0)
	v.add_child(holder)
	_add(holder, _petal_disc(6, br * 0.3, br, br * 0.25, 0.8, 6), _mat(_color(p, "bloom_petal_color", "#f6efe0"), 0.8, true), Vector3.ZERO)
	_add(holder, sphere, _mat(_color(p, "bloom_centre_color", "#e9c46a"), 0.8), Vector3(0.0, br * 0.1, 0.0), Vector3.ZERO, Vector3(br * 0.5, br * 0.35, br * 0.5))
	v.add_pop(holder, 0.6, 0.98, Vector3(0.1, 0.1, 0.1))


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

static func _num(d: Dictionary, key: String, fallback: float) -> float:
	return float(d.get(key, fallback))


static func _color(d: Dictionary, key: String, fallback: String) -> Color:
	return Color.html(str(d.get(key, fallback)))


static func _mat(color: Color, glow: float = 0.0, double_sided: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Unit-diameter low-poly sphere; scale the node to get an ellipsoid.
static func _sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh


static func _pivot(parent: Node3D, pos: Vector3, rot_deg: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees = rot_deg
	parent.add_child(n)
	return n


static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation_degrees = rot_deg
	inst.scale = scl
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


static func _add_stem(v: FlowerVisual, height: float, radius: float, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Stem"
	v.add_child(pivot)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.75
	mesh.bottom_radius = radius * 1.2
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	_add(pivot, mesh, _mat(color), Vector3(0.0, height * 0.5, 0.0))
	v.add_stem(pivot, 0.0, STEM_END)
	return pivot


## Flat (slightly cupped) flower disc: [param petals] lobes between radius
## [param inner] and [param outer]; [param sharp] > 1 gives pointed tips,
## < 1 rounded ones; [param rise] lifts the rim.
static func _petal_disc(petals: int, inner: float, outer: float, rise: float, sharp: float, segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total: int = petals * segs
	for i in range(total):
		var a0: float = TAU * float(i) / float(total)
		var a1: float = TAU * float(i + 1) / float(total)
		# Centre -> p0 -> p1 is clockwise seen from above (+Y), i.e. front-facing upwards.
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(_disc_point(a0, petals, inner, outer, rise, sharp))
		st.add_vertex(_disc_point(a1, petals, inner, outer, rise, sharp))
	st.generate_normals()
	return st.commit()


static func _disc_point(angle: float, petals: int, inner: float, outer: float, rise: float, sharp: float) -> Vector3:
	var shape: float = pow(absf(cos(angle * float(petals) * 0.5)), sharp)
	var r: float = inner + (outer - inner) * shape
	return Vector3(cos(angle) * r, rise * pow(r / outer, 2.0), sin(angle) * r)
