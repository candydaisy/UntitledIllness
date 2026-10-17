class_name DialogLog
extends PanelContainer
## Scrollable list of every line shown so far, plus the choices picked.
## Built in code so the dialog scene doesn't need extra nodes.

const DIM := Color(1, 1, 1, 0.6)
const CHOICE := Color(0.95, 0.85, 0.55)

var _lines : Array = [] # one BBCode string per entry
var _label : RichTextLabel


func _init(theme_from: Control) -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP # don't click through to the story
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if theme_from:
		theme = theme_from.theme

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	add_child(margin)

	var column := VBoxContainer.new()
	margin.add_child(column)

	# Touch screens have no L or Escape key, so the log needs its own way out.
	var back := Button.new()
	back.text = "Back"
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.custom_minimum_size = Vector2(140, 56) # big enough to tap
	back.focus_mode = Control.FOCUS_NONE # so Space/Enter don't press it
	back.accessibility_description = tr("Closes the log. Shortcut: L or Escape.")
	back.pressed.connect(toggle)
	column.add_child(back)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # story lines
	_label.scroll_following = true
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.add_theme_font_size_override("normal_font_size", 26)
	column.add_child(_label)


func _ready() -> void:
	# Same panel as before, just black instead of grey (keeps its transparency).
	var style := get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style = style.duplicate()
		style.bg_color = Color(0, 0, 0, style.bg_color.a)
		add_theme_stylebox_override("panel", style)


func add_line(speaker: String, text: String) -> void:
	var line := text.strip_edges()
	if speaker != "":
		line = "[color=#%s]%s[/color]\n%s" % [DIM.to_html(), speaker, line]
	_lines.append(line)
	_refresh()

func add_choice(text: String) -> void:
	_lines.append("[color=#%s]> %s[/color]" % [CHOICE.to_html(), text])
	_refresh()

## Removes the last n entries (used when rewinding).
func remove_last(n := 1) -> void:
	for i in mini(n, _lines.size()):
		_lines.pop_back()
	_refresh()


func get_lines() -> Array:
	return _lines.duplicate()

func set_lines(lines: Array) -> void:
	_lines = lines.duplicate()
	_refresh()


## Puts keyboard / screen reader focus on the log text so it can be read.
func focus_text() -> void:
	_label.focus_mode = Control.FOCUS_ALL
	_label.accessibility_name = tr("Dialog log")
	_label.accessibility_description = tr("Every line so far, oldest first. Press L or Escape to close.")
	_label.grab_focus()


func toggle() -> void:
	visible = not visible
	if visible:
		_label.scroll_to_line(_label.get_line_count())

func _refresh() -> void:
	_label.text = "\n\n".join(_lines)
