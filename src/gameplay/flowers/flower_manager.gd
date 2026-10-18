class_name FlowerManager
extends Node
## Seed / plant / water / bloom loop of the garden (Story 002,
## design/game-brief.md: cosy, no failure state, flowers are the reward).
##
## One seed at a time, in the order of assets/data/flowers.json
## (rencontre, boston, bague, forrest, seda, renaissance).
##
## Phase transition table (the only legal moves):
##   WAITING        --delay elapsed-------------> SEED_AVAILABLE  (or DONE when no seed is left)
##   SEED_AVAILABLE --pick_up_seed()------------> CARRYING
##   CARRYING       --plant_at(free plot)-------> PLANTED
##   PLANTED        --water_plot() < needed-----> PLANTED
##   PLANTED        --water_plot() == needed----> BLOOMING
##   BLOOMING       --bloom animation finished--> WAITING (emits flower_bloomed)
## Nothing can fail: a seed cannot be dropped, lost or destroyed; planting on an
## occupied plot is simply refused; nothing times out.
##
## Story 003 hook: connect to [signal flower_bloomed]. The manager is in group
## [constant MANAGER_GROUP]. (Pause the tree to freeze the manager while a memory
## scene is shown.)

## Emitted when a flower finished blooming. [param flower_id] is the id of
## assets/data/flowers.json ("rencontre", "boston", ...), [param plot] the FlowerPlot node.
signal flower_bloomed(flower_id: StringName, plot: Node3D)
## Emitted when the next seed appears in the garden.
signal seed_spawned(flower_id: StringName)
## Emitted when the carried seed changes; [param flower_id] is empty when nothing is carried.
signal carried_changed(flower_id: StringName, display_name: String, color: Color)
## Emitted when the contextual hint changes ([param text] empty = hide).
signal hint_changed(text: String, actionable: bool)
## Emitted when a seed is planted on a plot.
signal seed_planted(flower_id: StringName, plot: Node3D)
## Emitted on every watering.
signal seed_watered(flower_id: StringName, waterings: int, needed: int)

## Group name of the manager node (find it with get_tree().get_first_node_in_group).
const MANAGER_GROUP: StringName = &"flower_manager"
const CONFIG_PATH: String = "res://assets/data/flowers.json"
const DEMO_ARG_PREFIX: String = "--demo-state="
const ACTION_INTERACT: StringName = &"interact"

enum Phase { WAITING, SEED_AVAILABLE, CARRYING, PLANTED, BLOOMING, DONE }
enum SlotState { FREE, PLANTED, BLOOMING, BLOOMED }
enum AimKind { NONE, SEED, PLOT }

## State of one planting spot.
class PlotSlot extends RefCounted:
	var plot: Node3D
	var state: int = 0
	var flower_id: StringName = &""
	var waterings: int = 0
	var seed_model: SeedModel
	var flower: FlowerVisual

## What the crosshair currently points at.
class Aim extends RefCounted:
	var kind: int = 0
	var slot: PlotSlot

## Simulation speed multiplier (1.0 in the game; tests/debug may raise it).
var time_scale: float = 1.0

var _settings: Dictionary = {}
var _strings: Dictionary = {}
var _flowers: Array = []
var _demo: Dictionary = {}
var _slots: Array[PlotSlot] = []
var _world: Node3D
var _camera: Camera3D
var _player: GardenPlayer
var _ground_height: Callable
var _phase: int = Phase.WAITING
var _next_index: int = 0
var _current_index: int = -1
var _timer: float = 0.0
var _ground_seed: SeedModel
var _active_slot: PlotSlot
var _bloom_t: float = 0.0
var _bloomed_ids: Array[StringName] = []
var _last_hint_key: String = "?"
var _emit_bloom_signal: bool = true
# Debug capture state (see apply_demo_state).
var _bloom_frozen: bool = false
var _demo_water_interval: float = 0.0
var _demo_water_timer: float = 0.0


## Injects the scene dependencies. Call before adding the node to the tree.
## [param plots] are the FlowerPlot nodes, [param ground_height] a Callable (x, z) -> float.
func configure(camera: Camera3D, player: GardenPlayer, plots: Array[Node3D], ground_height: Callable) -> void:
	_camera = camera
	_player = player
	_ground_height = ground_height
	var sorted: Array[Node3D] = plots.duplicate()
	sorted.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return int(a.get_meta(&"plot_index", 0)) < int(b.get_meta(&"plot_index", 0)))
	for plot: Node3D in sorted:
		var slot := PlotSlot.new()
		slot.plot = plot
		slot.state = SlotState.FREE
		_slots.append(slot)


func _ready() -> void:
	add_to_group(MANAGER_GROUP)
	# Container for the seeds lying in the garden (the parent is busy while we are readied).
	_world = Node3D.new()
	_world.name = "Seeds"
	add_child(_world)
	_load_config()
	_begin_waiting(_f("first_seed_delay", 1.0))
	var demo_name: String = _demo_state_from_cmdline()
	if demo_name != "":
		apply_demo_state(demo_name)


func _process(delta: float) -> void:
	var dt: float = delta * time_scale
	match _phase:
		Phase.WAITING:
			_timer -= dt
			if _timer <= 0.0:
				_spawn_seed()
		Phase.BLOOMING:
			if not _bloom_frozen:
				_bloom_t += dt / maxf(_f("bloom_duration", 2.6), 0.1)
				_apply_bloom_progress()
				if _bloom_t >= 1.0:
					_finish_bloom()
	if _demo_water_interval > 0.0 and _active_slot != null:
		_demo_water_timer -= delta
		if _demo_water_timer <= 0.0:
			_demo_water_timer = _demo_water_interval
			_play_water_effect(_active_slot)
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ACTION_INTERACT):
		return
	# While the mouse is free, the first click only recaptures it (see GardenPlayer).
	if event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if try_interact():
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------------------
# Public API (logic; used by input and by tests)
# --------------------------------------------------------------------------

## Current phase of the seed loop (see the transition table above).
func get_phase() -> int:
	return _phase


## A player-facing string from the data file ("strings" block), or empty.
func get_string(key: String) -> String:
	return str(_strings.get(key, ""))


## Id of the seed currently in play (lying, carried, planted or blooming), or empty.
func get_current_flower_id() -> StringName:
	if _current_index < 0 or _current_index >= _flowers.size():
		return &""
	return StringName(str(_flowers[_current_index].get("id", "")))


## Ids of the flowers that have finished blooming, in order.
func get_bloomed_ids() -> Array[StringName]:
	return _bloomed_ids.duplicate()


## The planting-spot nodes managed here, ordered by plot index.
func get_plots() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for slot in _slots:
		result.append(slot.plot)
	return result


## True when nothing stands on [param plot] (free to plant).
func is_plot_free(plot: Node3D) -> bool:
	var slot: PlotSlot = _slot_for(plot)
	return slot != null and slot.state == SlotState.FREE


## Waterings the plant on [param plot] has received so far (0 when free).
func get_waterings(plot: Node3D) -> int:
	var slot: PlotSlot = _slot_for(plot)
	return 0 if slot == null else slot.waterings


## Performs the context action at the crosshair: pick up, plant or water.
## Returns true when something happened.
func try_interact() -> bool:
	var aim: Aim = _find_aim()
	if aim.kind == AimKind.SEED:
		return pick_up_seed()
	if aim.kind == AimKind.PLOT:
		if _phase == Phase.CARRYING:
			return plant_at(aim.slot.plot)
		return water_plot(aim.slot.plot)
	return false


## Picks up the seed lying in the garden. False if none is available.
func pick_up_seed() -> bool:
	if _phase != Phase.SEED_AVAILABLE:
		return false
	if _ground_seed != null:
		_ground_seed.queue_free()
		_ground_seed = null
	_phase = Phase.CARRYING
	var flower: Dictionary = _flowers[_current_index]
	carried_changed.emit(get_current_flower_id(), str(flower.get("display_name", "")), _flower_color(flower, "seed_color", "#ffd45a"))
	return true


## Plants the carried seed on [param plot]. Refused (false, nothing changes) when
## no seed is carried or the plot is occupied.
func plant_at(plot: Node3D) -> bool:
	var slot: PlotSlot = _slot_for(plot)
	if _phase != Phase.CARRYING or slot == null or slot.state != SlotState.FREE:
		return false
	var flower: Dictionary = _flowers[_current_index]
	slot.state = SlotState.PLANTED
	slot.flower_id = get_current_flower_id()
	slot.waterings = 0
	var model := SeedModel.new()
	model.name = "PlantedSeed"
	model.setup(_flower_color(flower, "seed_color", "#ffd45a"), _settings, false)
	model.position = Vector3(0.0, _f("planted_seed_height", 0.12), 0.0)
	plot.add_child(model)
	slot.seed_model = model
	_active_slot = slot
	_phase = Phase.PLANTED
	carried_changed.emit(&"", "", Color.WHITE)
	seed_planted.emit(slot.flower_id, plot)
	return true


## Waters the planted seed on [param plot]. After the configured number of
## waterings the bloom starts. False if nothing was watered.
func water_plot(plot: Node3D) -> bool:
	var slot: PlotSlot = _slot_for(plot)
	if _phase != Phase.PLANTED or slot == null or slot != _active_slot:
		return false
	_water(slot, true)
	return true


## Debug/capture only: jump to a named state. Used by --demo-state=<name>.
## Names: seeds, watering, blooming, garden-full, garden-full-close.
func apply_demo_state(state_name: String) -> void:
	match state_name:
		"seeds":
			_spawn_seed()
			if _player != null and _ground_seed != null:
				var pp: Array = _demo.get("seeds_player_pos", [-0.6, 5.6])
				_player.position = Vector3(float(pp[0]), 0.1, float(pp[1]))
				_player.face_point(_ground_seed.global_position + Vector3(0.0, float(_demo.get("seeds_look_height", 0.4)), 0.0))
		"watering", "blooming":
			_demo_stage_active_plant(state_name == "blooming")
		"garden-full":
			_demo_fill_garden(false)
		"garden-full-close":
			_demo_fill_garden(true)
		_:
			push_warning("FlowerManager: unknown demo state '%s'" % state_name)


# --------------------------------------------------------------------------
# Internals
# --------------------------------------------------------------------------

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("Flower config missing: %s" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Flower config is not a valid JSON object: %s" % CONFIG_PATH)
		return
	var root: Dictionary = parsed
	_settings = root.get("settings", {})
	_strings = root.get("strings", {})
	_flowers = root.get("flowers", [])
	_demo = root.get("demo", {})


func _f(key: String, fallback: float) -> float:
	return float(_settings.get(key, fallback))


func _flower_color(flower: Dictionary, key: String, fallback: String) -> Color:
	return Color.html(str(flower.get(key, fallback)))


func _slot_for(plot: Node3D) -> PlotSlot:
	for slot in _slots:
		if slot.plot == plot:
			return slot
	return null


func _begin_waiting(delay: float) -> void:
	_phase = Phase.WAITING
	_timer = delay


func _spawn_seed() -> void:
	if _next_index >= _flowers.size():
		_phase = Phase.DONE
		return
	_current_index = _next_index
	var flower: Dictionary = _flowers[_current_index]
	var pos: Array = flower.get("seed_pos", [0.0, 3.0])
	var x: float = float(pos[0])
	var z: float = float(pos[1])
	var ground: float = float(_ground_height.call(x, z)) if _ground_height.is_valid() else 0.0
	var model := SeedModel.new()
	model.name = "Seed_%s" % get_current_flower_id()
	model.setup(_flower_color(flower, "seed_color", "#ffd45a"), _settings, true)
	model.position = Vector3(x, ground + _f("seed_hover_height", 0.32), z)
	_world.add_child(model)
	model.appear(_f("seed_appear_duration", 0.7))
	_ground_seed = model
	_phase = Phase.SEED_AVAILABLE
	seed_spawned.emit(get_current_flower_id())


func _water(slot: PlotSlot, with_effect: bool) -> void:
	slot.waterings += 1
	var needed: int = maxi(int(_f("waterings_needed", 3.0)), 1)
	if with_effect:
		_play_water_effect(slot)
	slot.seed_model.set_sprout(float(slot.waterings) / float(needed + 1))
	seed_watered.emit(slot.flower_id, slot.waterings, needed)
	if slot.waterings >= needed:
		_start_bloom(slot)


func _play_water_effect(slot: PlotSlot) -> void:
	var effect: WateringEffect = WateringEffect.create(_settings)
	effect.position = slot.plot.position + Vector3(0.0, 0.1, 0.0)
	slot.plot.get_parent().add_child(effect)
	if slot.seed_model != null:
		slot.seed_model.react_to_water()


func _start_bloom(slot: PlotSlot) -> void:
	var flower: Dictionary = _flowers[_current_index]
	slot.state = SlotState.BLOOMING
	slot.flower = FlowerFactory.build(flower, _settings)
	slot.flower.position = Vector3(0.0, 0.09, 0.0)
	slot.plot.add_child(slot.flower)
	_bloom_t = 0.0
	_phase = Phase.BLOOMING
	_apply_bloom_progress()


func _apply_bloom_progress() -> void:
	if _active_slot == null or _active_slot.flower == null:
		return
	var p: float = clampf(_bloom_t, 0.0, 1.0)
	_active_slot.flower.set_progress(p)
	if _active_slot.seed_model != null:
		_active_slot.seed_model.set_shrink(p / maxf(_f("seed_shrink_end_progress", 0.25), 0.01))


func _finish_bloom() -> void:
	var slot: PlotSlot = _active_slot
	slot.flower.set_progress(1.0)
	if slot.seed_model != null:
		slot.seed_model.queue_free()
		slot.seed_model = null
	slot.state = SlotState.BLOOMED
	slot.flower.start_sway(_f("sway_amplitude_degrees", 2.4), _f("sway_speed", 1.3), float(slot.plot.get_meta(&"plot_index", 0)) * 1.7)
	var id: StringName = slot.flower_id
	_bloomed_ids.append(id)
	_active_slot = null
	_next_index += 1
	if _next_index >= _flowers.size():
		_phase = Phase.DONE
	else:
		_begin_waiting(_f("next_seed_delay", 3.0))
	if _emit_bloom_signal:
		if bool(_settings.get("debug_print", false)):
			print("[FlowerManager] flower_bloomed: %s (plot %s)" % [id, slot.plot.name])
		flower_bloomed.emit(id, slot.plot)


# --- Aiming and hints -------------------------------------------------------

## Distance along the view ray to [param point], or -1 when it is out of reach / off-aim.
func _ray_hit(point: Vector3, radius: float, origin: Vector3, forward: Vector3) -> float:
	var to_point: Vector3 = point - origin
	if to_point.length() > _f("reach", 3.2):
		return -1.0
	var along: float = to_point.dot(forward)
	if along <= 0.0:
		return -1.0
	var off_axis: float = (to_point - forward * along).length()
	return along if off_axis <= radius else -1.0


func _find_aim() -> Aim:
	var aim := Aim.new()
	if _camera == null or not _camera.is_inside_tree():
		return aim
	var origin: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var best: float = INF
	if _phase == Phase.SEED_AVAILABLE and _ground_seed != null:
		var hit: float = _ray_hit(_ground_seed.global_position, _f("aim_radius_seed", 0.5), origin, forward)
		if hit >= 0.0:
			best = hit
			aim.kind = AimKind.SEED
	for slot in _slots:
		var point: Vector3 = slot.plot.global_position + Vector3.UP * _f("plot_aim_height", 0.15)
		var plot_hit: float = _ray_hit(point, _f("aim_radius_plot", 0.75), origin, forward)
		if plot_hit >= 0.0 and plot_hit < best:
			best = plot_hit
			aim.kind = AimKind.PLOT
			aim.slot = slot
	return aim


func _hint_key_for(aim: Aim) -> String:
	if aim.kind == AimKind.SEED and _phase == Phase.SEED_AVAILABLE:
		return "hint_pickup"
	if aim.kind == AimKind.PLOT:
		if _phase == Phase.CARRYING:
			return "hint_plant" if aim.slot.state == SlotState.FREE else "hint_occupied"
		if _phase == Phase.PLANTED and aim.slot == _active_slot:
			return "hint_water"
		return ""
	if _phase == Phase.CARRYING:
		return "hint_carrying"
	return ""


func _update_hint() -> void:
	var key: String = _hint_key_for(_find_aim())
	if key == _last_hint_key:
		return
	_last_hint_key = key
	var actionable: bool = key == "hint_pickup" or key == "hint_plant" or key == "hint_water"
	hint_changed.emit("" if key == "" else str(_strings.get(key, "")), actionable)


# --- Debug capture states ---------------------------------------------------

func _demo_state_from_cmdline() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(DEMO_ARG_PREFIX):
			return arg.substr(DEMO_ARG_PREFIX.length())
	return ""


## Debug: flower 1 planted on the staging plot; optionally frozen mid-bloom.
func _demo_stage_active_plant(frozen_bloom: bool) -> void:
	if _slots.is_empty():
		return
	var plot_index: int = clampi(int(_demo.get("stage_plot", 2)), 0, _slots.size() - 1)
	var slot: PlotSlot = _slots[plot_index]
	_spawn_seed()
	pick_up_seed()
	plant_at(slot.plot)
	var needed: int = maxi(int(_f("waterings_needed", 3.0)), 1)
	if frozen_bloom:
		_emit_bloom_signal = false
		for i in range(needed):
			_water(slot, false)
		_bloom_frozen = true
		_bloom_t = float(_demo.get("frozen_bloom_progress", 0.72))
		_apply_bloom_progress()
		slot.flower.set_sparkles_looping(true)
		slot.flower.set_progress(_bloom_t)
	else:
		_water(slot, false)
		_demo_water_interval = float(_demo.get("water_loop_interval", 1.4))
		_demo_water_timer = 0.0
	if _player != null:
		var pp: Array = _demo.get("stage_player_pos", [-0.9, 3.4])
		_player.position = Vector3(float(pp[0]), 0.1, float(pp[1]))
		_player.face_point(slot.plot.global_position + Vector3(0.0, float(_demo.get("stage_look_height", 0.3)), 0.0))


## Debug: all six flowers bloomed instantly (no signals emitted).
func _demo_fill_garden(close_view: bool) -> void:
	_emit_bloom_signal = false
	var needed: int = maxi(int(_f("waterings_needed", 3.0)), 1)
	for i in range(mini(_flowers.size(), _slots.size())):
		_spawn_seed()
		pick_up_seed()
		plant_at(_slots[i].plot)
		for k in range(needed):
			_water(_slots[i], false)
		_bloom_t = 1.0
		_finish_bloom()
	_emit_bloom_signal = true
	if close_view and _player != null:
		# Debug: stand ~2 m from the three small flowers on the right.
		var pp: Array = _demo.get("close_player_pos", [2.9, 3.4])
		var la: Array = _demo.get("close_look_at", [2.9, 1.2])
		_player.position = Vector3(float(pp[0]), 0.1, float(pp[1]))
		_player.face_point(Vector3(float(la[0]), float(_demo.get("close_look_height", 0.45)), float(la[1])))
