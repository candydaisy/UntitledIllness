class_name StoryStage
extends RefCounted
## Backgrounds, character sprites and expressions. Nodes are found by name,
## so a flow graph's "background": "Gate" shows the Bgs child named Gate.

const FADE_TIME := 0.67

var host : Node # creates the tweens
var backgrounds : Node
var characters : Node

var _tweens := {} # CanvasItem -> Tween


func _init(host_node: Node, bgs: Node, chars: Node) -> void:
	host = host_node
	backgrounds = bgs
	characters = chars


func has_background(bg_name: String) -> bool:
	return backgrounds.has_node(NodePath(bg_name))

func has_character(char_name: String) -> bool:
	return characters.has_node(NodePath(char_name))

func has_expression(char_name: String, anim: String) -> bool:
	var n := characters.get_node_or_null(NodePath(char_name)) as AnimatedSprite2D
	return n != null and n.sprite_frames != null and n.sprite_frames.has_animation(anim)


## Applies a node's "background", "show_characters", "hide_characters" and
## "expression" keys. All fades run together; awaits until they finish.
func apply(entry: Dictionary) -> void:
	var tweens := []

	if entry.has("background"):
		for bg in backgrounds.get_children():
			tweens.append(_fade(bg, bg.name == entry["background"]))

	for char_name in entry.get("show_characters", []):
		var n := characters.get_node_or_null(NodePath(char_name))
		if n:
			tweens.append(_fade(n, true))

	for char_name in entry.get("hide_characters", []):
		var n := characters.get_node_or_null(NodePath(char_name))
		if n:
			tweens.append(_fade(n, false))

	var expressions : Dictionary = entry.get("expression", {})
	for char_name in expressions:
		_play_expression(char_name, expressions[char_name])

	await _await_all(tweens)


## What's on screen right now, for rewinding.
func snapshot() -> Dictionary:
	var bgs := []
	for bg in backgrounds.get_children():
		if bg.visible:
			bgs.append(String(bg.name))
	var chars := {}
	for n in characters.get_children():
		if n.visible:
			chars[String(n.name)] = String(n.animation) if n is AnimatedSprite2D else ""
	return { "backgrounds": bgs, "characters": chars }

func restore(state: Dictionary) -> void:
	var tweens := []
	for bg in backgrounds.get_children():
		tweens.append(_fade(bg, String(bg.name) in state["backgrounds"]))
	for n in characters.get_children():
		var char_name := String(n.name)
		tweens.append(_fade(n, state["characters"].has(char_name)))
		if state["characters"].get(char_name, "") != "":
			_play_expression(char_name, state["characters"][char_name])
	await _await_all(tweens)


func _play_expression(char_name: String, anim: String) -> void:
	if has_expression(char_name, anim):
		characters.get_node(NodePath(char_name)).play(anim)


## Fades a node in or out. Returns the Tween, or null if nothing changes.
func _fade(node: CanvasItem, show: bool) -> Tween:
	var running : Tween = _tweens.get(node)
	if running and running.is_valid():
		running.kill()

	if show:
		if not node.visible:
			node.modulate.a = 0.0
			node.visible = true
		if node.modulate.a >= 1.0:
			return null
	elif not node.visible:
		return null

	var t := host.create_tween()
	t.tween_property(node, "modulate:a", 1.0 if show else 0.0, FADE_TIME)
	if not show:
		t.tween_callback(node.hide)
	_tweens[node] = t
	return t

func _await_all(tweens: Array) -> void:
	for t in tweens:
		if t and t.is_running():
			await t.finished
