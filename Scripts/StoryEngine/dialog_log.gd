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

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.scroll_following = true
	_label.add_theme_font_size_override("normal_font_size", 26)
	margin.add_child(_label)


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


func toggle() -> void:
	visible = not visible
	if visible:
		_label.scroll_to_line(_label.get_line_count())

func _refresh() -> void:
	_label.text = "\n\n".join(_lines)
