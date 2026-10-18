class_name GardenHud
extends CanvasLayer
## Minimal garden HUD (Story 002): centre dot, one-line hint, carried-seed indicator.
##
## Purely presentational: it receives text and colours through its public setters
## (wired to [FlowerManager] signals by the garden). It holds no player-facing
## strings of its own; they all come from assets/data/flowers.json.
## Every Control ignores the mouse so it never swallows a click.

const DOT_SIZE: float = 6.0
const DOT_SIZE_ACTIVE: float = 10.0
const DOT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const DOT_COLOR_ACTIVE: Color = Color(1.0, 0.93, 0.6, 1.0)
const HINT_FONT_SIZE: int = 26
const CARRIED_FONT_SIZE: int = 20
const OUTLINE_COLOR: Color = Color(0.12, 0.16, 0.1, 0.85)

var _dot: Panel
var _dot_style: StyleBoxFlat
var _hint: Label
var _carried_box: HBoxContainer
var _carried_icon: Panel
var _carried_icon_style: StyleBoxFlat
var _carried_label: Label
var _carried_format: String = "%s"


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_dot_style = StyleBoxFlat.new()
	_dot_style.set_corner_radius_all(8)
	_dot_style.border_color = OUTLINE_COLOR
	_dot_style.set_border_width_all(1)
	_dot = Panel.new()
	_dot.name = "CrosshairDot"
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.add_theme_stylebox_override("panel", _dot_style)
	root.add_child(_dot)
	_set_dot(false)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -110.0
	_hint.offset_bottom = -60.0
	_style_label(_hint, HINT_FONT_SIZE)
	root.add_child(_hint)

	_carried_box = HBoxContainer.new()
	_carried_box.name = "Carried"
	_carried_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carried_box.position = Vector2(28.0, 24.0)
	_carried_box.add_theme_constant_override("separation", 10)
	_carried_box.visible = false
	root.add_child(_carried_box)
	_carried_icon_style = StyleBoxFlat.new()
	_carried_icon_style.set_corner_radius_all(14)
	_carried_icon_style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	_carried_icon_style.set_border_width_all(2)
	_carried_icon = Panel.new()
	_carried_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carried_icon.custom_minimum_size = Vector2(20.0, 30.0)
	_carried_icon.add_theme_stylebox_override("panel", _carried_icon_style)
	_carried_box.add_child(_carried_icon)
	_carried_label = Label.new()
	_carried_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(_carried_label, CARRIED_FONT_SIZE)
	_carried_box.add_child(_carried_label)


## Sets the format used for the carried label (e.g. "Graine : %s"), from the data file.
func set_carried_format(format: String) -> void:
	_carried_format = format


## Shows [param text] as the hint line (empty hides it); [param actionable] enlarges the dot.
func set_hint(text: String, actionable: bool) -> void:
	_hint.text = text
	_hint.visible = text != ""
	_set_dot(actionable)


## Shows the carried seed (small coloured seed + its name); empty [param flower_id] hides it.
func set_carried(flower_id: StringName, display_name: String, color: Color) -> void:
	_carried_box.visible = flower_id != &""
	_carried_label.text = _carried_format % display_name if _carried_format.contains("%s") else display_name
	_carried_icon_style.bg_color = color


func _set_dot(active: bool) -> void:
	var size: float = DOT_SIZE_ACTIVE if active else DOT_SIZE
	_dot_style.bg_color = DOT_COLOR_ACTIVE if active else DOT_COLOR
	_dot.set_anchors_preset(Control.PRESET_CENTER)
	_dot.offset_left = -size * 0.5
	_dot.offset_right = size * 0.5
	_dot.offset_top = -size * 0.5
	_dot.offset_bottom = size * 0.5


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 7)
