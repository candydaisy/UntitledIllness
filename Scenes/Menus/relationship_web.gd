class_name RelationshipWeb
extends Control
## Obsidian-style relationship graph. Every character and link comes from
## Story/relationships.json; nothing about the cast is written in this script.
##
## Playable characters are colored dots (their "color" in the JSON), everyone
## else is grey. Click a dot to select it: its lines light up in its color, each
## connected character shows what they are to the selected one, and the panel
## on the right shows the picture and details. Drag dots to move them, drag
## empty space to pan, scroll to zoom, click empty space to deselect.

@export_file("*.json") var data_path := "res://Story/relationships.json"
@export_dir var story_dir := "res://Story/" # checked for speakers missing from data_path
@export var other_color := Color(0.62, 0.62, 0.62)
@export var line_color := Color(1, 1, 1, 0.18)
@export var link_length := 210.0

const PLAYABLE_RADIUS := 16.0
const OTHER_RADIUS := 10.0
const NAME_SIZE := 16
const TAG_SIZE := 15
const REPULSION := 30000.0
const SPRING := 0.02
const GRAVITY := 0.004
const DAMPING := 0.85
const COOLING := 0.995 # the layout slowly settles; dragging wakes it up
const ZOOM_RANGE := Vector2(0.4, 2.5)

@onready var info_panel : Panel = $InfoPanel
@onready var picture : TextureRect = $InfoPanel/Picture
@onready var initial : Label = $InfoPanel/Initial
@onready var name_label : Label = $InfoPanel/Name
@onready var about_label : Label = $InfoPanel/About
@onready var links_label : RichTextLabel = $InfoPanel/Links

var nodes := {} # id -> {name, color, playable, picture, about, speaker, route, pos, vel}
var links : Array = [] # {from, to, to_is, from_is}
var ignore_speakers : Array = []
var selected := ""
var hovered := ""

var _relations := {} # other id -> what they are to `selected`
var _dragging := ""
var _panning := false
var _drag_moved := false
var _offset := Vector2.ZERO
var _zoom := 1.0
var _heat := 1.0


func _ready() -> void:
	# Keyboard and screen readers: arrow keys move between characters, and each
	# one is announced with their connections (the web itself is only drawn).
	focus_mode = Control.FOCUS_ALL
	accessibility_name = "Relationship web"
	accessibility_description = "Arrow keys: move between characters. Escape: clear."
	Accessibility.make_live(self)
	_load()
	if OS.is_debug_build():
		_check_story_speakers()
	_select("")


func _process(_delta: float) -> void:
	if _heat > 0.01 or _dragging != "":
		_simulate()
	queue_redraw()



# --- Data ---

func _load() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(data_path))
	if not data is Dictionary:
		push_error("Relationship web: couldn't read " + data_path)
		return
	ignore_speakers = data.get("ignore_speakers", [])

	var characters : Array = data.get("characters", [])
	for i in characters.size():
		var c : Dictionary = characters[i]
		var playable : bool = c.get("playable", false)
		var angle := TAU * i / characters.size()
		nodes[c["id"]] = {
			"name": c.get("name", c["id"]),
			"speaker": c.get("speaker", c.get("name", c["id"])),
			"route": c.get("route", ""),
			"playable": playable,
			"color": Color.html(c["color"]) if playable and c.has("color") else other_color,
			"picture": c.get("picture", ""),
			"about": c.get("about", ""),
			"pos": Vector2.from_angle(angle) * (120.0 if playable else 300.0),
			"vel": Vector2.ZERO,
		}

	for l in data.get("links", []):
		if not nodes.has(l.get("from")) or not nodes.has(l.get("to")):
			push_warning("Relationship web: link %s -> %s uses an unknown id" % [l.get("from"), l.get("to")])
			continue
		links.append(l)


## Warns about anyone who speaks in a story but isn't in the relationship file.
func _check_story_speakers() -> void:
	var dir := DirAccess.open(story_dir)
	if dir == null:
		return
	for route in dir.get_directories():
		var path := story_dir.path_join(route).path_join("flow_graph.json")
		if not FileAccess.file_exists(path):
			continue
		var graph := FlowGraph.load_from(path)
		if graph == null:
			continue
		var speakers := {}
		for entry in graph.nodes.values():
			speakers[entry.get("speaker", "")] = true
		for speaker in speakers:
			if speaker not in ignore_speakers and not _has_speaker(speaker, route):
				push_warning("Relationship web: '%s' speaks in %s's story but isn't in %s" % [speaker, route, data_path])

func _has_speaker(speaker: String, route: String) -> bool:
	for n in nodes.values():
		if n["speaker"] == speaker and (n["route"] == "" or n["route"] == route):
			return true
	return false



# --- Layout (a small force simulation, like Obsidian's graph view) ---

func _simulate() -> void:
	var ids := nodes.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a : Dictionary = nodes[ids[i]]
			var b : Dictionary = nodes[ids[j]]
			var d : Vector2 = a["pos"] - b["pos"]
			var f := d.normalized() * REPULSION / maxf(d.length_squared(), 100.0)
			a["vel"] += f
			b["vel"] -= f
	for l in links:
		var a : Dictionary = nodes[l["from"]]
		var b : Dictionary = nodes[l["to"]]
		var d : Vector2 = b["pos"] - a["pos"]
		var f := d.normalized() * (d.length() - link_length) * SPRING
		a["vel"] += f
		b["vel"] -= f
	for id in nodes:
		var n : Dictionary = nodes[id]
		n["vel"] -= n["pos"] * GRAVITY
		n["vel"] *= DAMPING
		if id != _dragging:
			n["pos"] += n["vel"] * _heat
	_heat *= COOLING



# --- Drawing ---

func _graph_center() -> Vector2:
	var width := size.x - (info_panel.size.x if info_panel.visible else 0.0)
	return Vector2(width / 2.0, size.y / 2.0) + _offset

func _to_screen(p: Vector2) -> Vector2:
	return _graph_center() + p * _zoom

func _to_graph(p: Vector2) -> Vector2:
	return (p - _graph_center()) / _zoom

func _radius(n: Dictionary) -> float:
	return (PLAYABLE_RADIUS if n["playable"] else OTHER_RADIUS) * sqrt(_zoom)


func _draw() -> void:
	var font := get_theme_font("font", "Label") # same font as the panel
	var lit_color : Color = nodes[selected]["color"] if selected != "" else Color.WHITE
	if selected != "" and not nodes[selected]["playable"]:
		lit_color = Color(1, 1, 1, 0.9) # grey lines would be invisible

	for l in links:
		var lit : bool = selected != "" and (l["from"] == selected or l["to"] == selected)
		var color := lit_color if lit else line_color
		if selected != "" and not lit:
			color.a *= 0.35
		draw_line(_to_screen(nodes[l["from"]]["pos"]), _to_screen(nodes[l["to"]]["pos"]), color, 3.0 if lit else 1.5, true)

	for id in nodes:
		var n : Dictionary = nodes[id]
		var p := _to_screen(n["pos"])
		var r := _radius(n)
		var dim : bool = selected != "" and id != selected and not _relations.has(id)
		var color : Color = n["color"]
		if dim:
			color.a = 0.3
		if id == hovered or id == selected:
			draw_circle(p, r + 5.0, Color(color, 0.3))
		draw_circle(p, r, color)

		var name_alpha : float = 0.3 if dim else 0.95
		_draw_centered(font, n["name"], p + Vector2(0, r + 18), NAME_SIZE, Color(1, 1, 1, name_alpha))
		if _relations.has(id):
			_draw_centered(font, _relations[id], p + Vector2(0, r + 36), TAG_SIZE, lit_color)

func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at - Vector2(w / 2.0, 0)
	# Dark outline so names stay readable where lines cross them.
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0, 0, 0, color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)



# --- Input ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ids := nodes.keys()
		var at := ids.find(selected)
		if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			_select(ids[(at + 1) % ids.size()])
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			_select(ids[(at - 1 + ids.size()) % ids.size()] if at >= 0 else ids[-1])
		elif event.is_action_pressed("ui_cancel") and selected != "":
			_select("")
		else:
			return
		accept_event()
		return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_dragging = _node_at(event.position)
					_panning = _dragging == ""
					_drag_moved = false
				else:
					if not _drag_moved:
						_select(_dragging) # clicking empty space deselects
					_dragging = ""
					_panning = false
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_at(event.position, 1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_at(event.position, 1.0 / 1.1)
	elif event is InputEventMouseMotion:
		if event.relative.length() > 1.0 and (_dragging != "" or _panning):
			_drag_moved = true
		if _dragging != "":
			nodes[_dragging]["pos"] = _to_graph(event.position)
			nodes[_dragging]["vel"] = Vector2.ZERO
			_heat = 1.0
		elif _panning:
			_offset += event.relative
		else:
			hovered = _node_at(event.position)
			mouse_default_cursor_shape = CURSOR_POINTING_HAND if hovered != "" else CURSOR_ARROW

func _node_at(screen_pos: Vector2) -> String:
	for id in nodes:
		var n : Dictionary = nodes[id]
		if _to_screen(n["pos"]).distance_to(screen_pos) <= _radius(n) + 6.0:
			return id
	return ""

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _to_graph(screen_pos)
	_zoom = clampf(_zoom * factor, ZOOM_RANGE.x, ZOOM_RANGE.y)
	_offset += screen_pos - _to_screen(before)



# --- Selection and the info panel ---

func _select(id: String) -> void:
	selected = id
	_relations.clear()
	for l in links:
		if l["from"] == id:
			_relations[l["to"]] = l.get("to_is", "")
		elif l["to"] == id:
			_relations[l["from"]] = l.get("from_is", "")
	_show_info(id)

## What a screen reader says for the selected character.
func _speech(id: String) -> String:
	if id == "":
		return "Relationship web. %d characters. Use the arrow keys to move between them." % nodes.size()
	var n : Dictionary = nodes[id]
	var links := []
	for other in _relations:
		links.append("%s, %s" % [nodes[other]["name"], _relations[other]])
	return "%s%s. %s Connected to: %s." % [n["name"], ", playable" if n["playable"] else "", n["about"], "; ".join(links) if links else "nobody yet"]

func _show_info(id: String) -> void:
	Accessibility.say(self, _speech(id))
	if id == "":
		name_label.text = "Relationships"
		about_label.text = "Click someone to see how they're connected. Drag to move, scroll to zoom."
		picture.visible = false
		initial.visible = false
		links_label.text = ""
		return

	var n : Dictionary = nodes[id]
	name_label.text = n["name"]
	about_label.text = n["about"]

	var tex : Texture2D = load(n["picture"]) if n["picture"] != "" and ResourceLoader.exists(n["picture"]) else null
	picture.texture = tex
	picture.visible = tex != null
	initial.visible = tex == null # placeholder until there's art
	initial.text = n["name"].left(1)
	initial.add_theme_color_override("font_color", n["color"])

	var lines := []
	for other in _relations:
		var o : Dictionary = nodes[other]
		lines.append("[color=#%s]●[/color] %s — %s" % [o["color"].to_html(false), o["name"], _relations[other]])
	links_label.text = "\n".join(lines)
