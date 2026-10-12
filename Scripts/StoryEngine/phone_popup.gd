class_name PhonePopup
extends PanelContainer
## An incoming call shown over the dialog instead of the choice buttons.
## Used for nodes with a "call" key: the node's choices become the buttons
## (e.g. Decline / Answer). Built in code so the dialog scene doesn't need it.

signal picked(index: int)

const RING_PULSE := 0.6 # seconds per pulse while ringing

var _caller : Label
var _buttons : HBoxContainer
var _ring_bar : ColorRect
var _pulse : Tween


func _init(theme_from: Control) -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	if theme_from:
		theme = theme_from.theme
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	custom_minimum_size = Vector2(420, 0)
	position = Vector2(-210, 120)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var incoming := Label.new()
	incoming.text = "incoming call"
	incoming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	incoming.modulate = Color(1, 1, 1, 0.6)
	box.add_child(incoming)

	_caller = Label.new()
	_caller.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caller.add_theme_font_size_override("font_size", 40)
	box.add_child(_caller)

	_ring_bar = ColorRect.new()
	_ring_bar.custom_minimum_size = Vector2(0, 4)
	_ring_bar.color = Color(1, 1, 1, 0.8)
	box.add_child(_ring_bar)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	box.add_child(_buttons)


func _ready() -> void:
	# Use the character's Panel style (border color etc.), a little more solid.
	var style := get_theme_stylebox("panel", "Panel")
	if style is StyleBoxFlat:
		style = style.duplicate()
		style.bg_color = Color(0, 0, 0, 0.85)
		add_theme_stylebox_override("panel", style)


## choices: the filtered choices (with "locked") to show as buttons.
func ring(caller: String, choices: Array) -> void:
	_caller.text = caller
	for b in _buttons.get_children():
		b.queue_free()
	for i in choices.size():
		var b := Button.new()
		b.text = choices[i].get("text", "")
		b.custom_minimum_size = Vector2(150, 56)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = choices[i].get("locked", false)
		b.modulate = Color(1, 1, 1, 0.35 if b.disabled else 1.0)
		b.pressed.connect(func(): picked.emit(i))
		_buttons.add_child(b)
	set_progress(1.0)
	visible = true
	pivot_offset = size / 2.0
	if _pulse and _pulse.is_valid():
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_property(self, "scale", Vector2(1.03, 1.03), RING_PULSE / 2.0)
	_pulse.tween_property(self, "scale", Vector2.ONE, RING_PULSE / 2.0)

func hang_up() -> void:
	visible = false
	if _pulse and _pulse.is_valid():
		_pulse.kill()
	scale = Vector2.ONE

## How much of the ring time is left, 0-1.
func set_progress(ratio: float) -> void:
	_ring_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ring_bar.custom_minimum_size.x = 380.0 * clampf(ratio, 0.0, 1.0)
