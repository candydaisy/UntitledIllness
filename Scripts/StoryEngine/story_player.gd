class_name StoryPlayer
extends Node2D
## Plays a character's story from a flow graph JSON.
## Reuse this script for every character's story scene: set flow_graph_path,
## start_node and mode in the Inspector. The mode (KayMode, ElysiaMode, ...)
## decides the character's meters, choice rules and effects; see StoryMode.
## The scene needs the same node layout as Story.tscn: Bgs, Characters, Audio
## and Cenfix/Dialog.

@export_file("*.json") var flow_graph_path := "res://Story/Kay/flow_graph.json"
@export_file("*.tscn") var end_scene_path := "res://Scenes/Menus/title_menu.tscn" # when story ends
@export var start_node := "1"
@export var mode : StoryMode # empty = KayMode with default settings
@export var ui_theme : Theme # this character's look for the dialog box, buttons, log and in-game menu
@export var notice_color := Color("f2b33d") # clickable details: {eyes are red|NoticedRedEyes}
@export var choice_delay := 1.5
@export var auto_delay := 1.2 # seconds Auto waits after a line finishes...
@export var auto_delay_per_char := 0.03 # ...plus this per character, so long lines stay up longer
@export var debug_log := false # print node and meters on every node

@onready var type_sound : AudioStreamPlayer = $Audio/typing
@onready var sfx_player : AudioStreamPlayer = $Audio/sfx
@onready var voice_player : AudioStreamPlayer = $Audio/voice
@onready var amb_player : AudioStreamPlayer = $Audio/amb #looping
@onready var characters_container : Node = $Characters
@onready var bgs_container : Node = $Bgs
@onready var dialog := $Cenfix/Dialog #dialog panel
@onready var speaker_label : Label = dialog.speaker
@onready var text_label : RichTextLabel = dialog.dialog_line #dialog text
@onready var choices_container : Control = $Cenfix/Dialog/Buttons/Choices
@onready var choice_buttons := [
	$Cenfix/Dialog/Buttons/Choices/choice1,
	$Cenfix/Dialog/Buttons/Choices/choice2,
	$Cenfix/Dialog/Buttons/Choices/choice3,
]
@onready var auto_button : Button = $Cenfix/Dialog/Buttons/Others/Auto
@onready var log_button : Button = $Cenfix/Dialog/Buttons/Others/Log
@onready var menu_button : Button = $Cenfix/Dialog/Buttons/Others/Setting
@onready var setting_menu : SettingMenu = $Cenfix/Dialog/Setting


const BASE_TYPING_SPEED := 30.0

const EMOTION_MULTIPLIERS := {
	"angry":   1.8,
	"tired":   0.6,
	"sad":     0.5,
	"nervous": 0.8,
} #typing speed

const NOTICE := "\\{([^{}|]+)\\|([A-Za-z0-9_]+)\\}" # {shown text|FlagName}
const NOTICED_ALPHA := 0.55 # a detail fades a little once it's been noticed

const TIMER_BAR_HEIGHT := 6.0
const TIMER_BAR_COLOR  := Color(1, 1, 1, 0.8)


var graph : FlowGraph
var typewriter : Typewriter
var stage : StoryStage
var audio : StoryAudio
var world_tint : CanvasModulate # tints everything outside the dialog CanvasLayer

var current_node := ""
var emotion_multiplier := 1.0
var flags := {} # (key: String - bool)
var is_transitioning := false
var current_choices := []
var node_history : Array = []
var pending_secret := ""
var auto_mode := false
var dialog_log : DialogLog
var timer_bar : ColorRect # shrinks while a timed choice is waiting
var phone : PhonePopup # incoming calls ("call" nodes)

var _node_serial := 0 # bumped on every node change so stale awaits can bail out
var _choice_time := 0.0 # length of the current timed choice, 0 = untimed
var _choice_time_left := 0.0
var _line_speed := 1.0 # this line's speed from the mode (quiet / rushing)
var _hovered_notice := "" # a {detail|Flag} under the mouse
var _notice_regex := RegEx.create_from_string(NOTICE)
var _current_line := {} # what mode.line_for returned for the current node



func _ready() -> void:
	choices_container.visible = false  # Hide choices

	graph = FlowGraph.load_from(flow_graph_path)
	if graph == null:
		return

	typewriter = Typewriter.new(text_label, type_sound)
	stage      = StoryStage.new(self, bgs_container, characters_container)
	audio      = StoryAudio.new(self, sfx_player, amb_player, voice_player)
	world_tint = CanvasModulate.new()
	add_child(world_tint)

	# Duplicate so meters don't leak into the scene file or the next playthrough.
	mode = mode.duplicate() if mode else KayMode.new()
	mode.setup(self)

	typewriter.finished.connect(_show_choices)
	typewriter.finished.connect(_auto_advance)
	for i in choice_buttons.size():
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

	if ui_theme:
		_apply_theme(dialog) # before the log copies the dialog box's theme
	dialog_log = DialogLog.new(dialog.get_node("DialogBox"))
	dialog.add_child(dialog_log)

	phone = PhonePopup.new(dialog.get_node("DialogBox"))
	dialog.add_child(phone)
	phone.picked.connect(_on_choice_pressed)

	text_label.bbcode_enabled = true
	text_label.meta_clicked.connect(_on_notice_clicked)
	text_label.meta_hover_started.connect(func(meta): _hovered_notice = str(meta))
	text_label.meta_hover_ended.connect(func(_meta): _hovered_notice = "")
	_setup_button(auto_button, "Auto", _toggle_auto)
	_setup_button(log_button, "Log", dialog_log.toggle)
	_setup_button(menu_button, "Menu", setting_menu.open)
	setting_menu.visible = false

	timer_bar = ColorRect.new()
	timer_bar.color = TIMER_BAR_COLOR
	timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_bar.visible = false
	choices_container.add_child(timer_bar)

	if OS.is_debug_build():
		_validate()

	if not SaveGame.pending.is_empty():
		var data := SaveGame.pending
		SaveGame.pending = {}
		_restore_save(data)
		return

	mode.apply_effects(true)
	current_node = start_node
	process_node(current_node)


func _process(delta: float) -> void:
	if typewriter:
		typewriter.tick(delta)
	_tick_choice_timer(delta)


func _input(event: InputEvent) -> void:
	if graph == null or event.is_echo():
		return

	if setting_menu.visible:
		if event.is_action_pressed("ui_cancel"):
			setting_menu.close()
			get_viewport().set_input_as_handled()
		return # the menu handles its own clicks
	if event.is_action_pressed("ui_cancel") and not dialog_log.visible:
		setting_menu.open()
		get_viewport().set_input_as_handled()
		return

	if dialog_log.visible:
		# The log covers the Log button, so check its area by hand. Esc also closes.
		var on_log_button : bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
				and event.pressed and log_button.get_global_rect().has_point(event.position)
		if on_log_button or event.is_action_pressed("ui_cancel"):
			dialog_log.toggle()
		return # scrolling and clicks belong to the log while it's open
	if is_transitioning:
		return
	# Clicking Auto, Log, a choice or a detail to notice shouldn't also advance the dialog.
	if event is InputEventMouseButton and (get_viewport().gui_get_hovered_control() is BaseButton or _hovered_notice != ""):
		return

	if event.is_action_pressed("dialog_deprocess"):
		_handle_rewind()
	elif event.is_action_pressed("dialog_process"):
		_handle_advance()



func _handle_rewind() -> void:
	if node_history.is_empty() or node_history.back().get("from_choice", false):
		return

	typewriter.stop()
	pending_secret = ""
	choices_container.visible = false
	phone.hang_up()
	dialog_log.remove_last(2) # this line, and the one about to be shown again

	var s = node_history.pop_back()
	current_node = s["node"]
	flags = s["flags"]
	emotion_multiplier = s["emotion_multiplier"]
	mode.set_meters(s["meters"])
	mode.apply_effects()

	is_transitioning = true
	await stage.restore(s["stage"])
	process_node(current_node)


func _handle_advance() -> void:
	var entry := graph.get_entry(current_node)
	if typewriter.is_typing:
		if mode.can_skip(entry):
			typewriter.skip()
		return

	if entry.has("choices"):
		return

	var next : String = pending_secret if pending_secret != "" else entry.get("next", "")
	if next == "":
		get_tree().change_scene_to_file(end_scene_path)
		return

	_push_history(current_node)
	current_node = next
	process_node(current_node)


func _push_history(node: String, from_choice := false) -> void:
	node_history.append({
		"node":node,
		"meters":mode.get_meters(),
		"emotion_multiplier":emotion_multiplier,
		"from_choice":from_choice,
		"flags":flags.duplicate(),
		"stage":stage.snapshot(),
	})



func process_node(node_name: String) -> void:
	_node_serial += 1
	var serial := _node_serial
	choices_container.visible = false
	phone.hang_up()

	if not graph.has_entry(node_name):
		push_error("Flow graph has no node: " + node_name)
		return
	var entry := graph.get_entry(node_name)

	is_transitioning = true
	pending_secret = graph.secret_target(entry, mode.get_meters(), flags)
	audio.apply_amb(entry)
	await stage.apply(entry)
	if serial != _node_serial:
		return
	is_transitioning = false

	audio.apply_sfx(entry)
	audio.apply_voice(entry)
	speaker_label.text = entry.get("speaker", "")
	_line_speed = mode.line_speed(entry)
	apply_emotion(entry.get("emotion", ""))

	_current_line = mode.line_for(entry)
	var line := _current_line
	if line.has("unsaid"):
		var cut : bool = line.get("cut", false)
		typewriter.start_edit(_render(line["unsaid"]), _render(line["text"]), cut)
		var unsaid := _plain(line["unsaid"]).strip_edges()
		dialog_log.add_line(speaker_label.text, "%s\n%s" % [unsaid if cut else "[s]%s[/s]" % unsaid, _plain(line["text"]).strip_edges()])
	else:
		typewriter.start(_render(line["text"]))
		dialog_log.add_line(speaker_label.text, _plain(line["text"]))

	if debug_log:
		print("node ", node_name, " | ", mode.describe())



## Gives every themed Control in the dialog (and the in-game menu inside it)
## this character's theme. Controls without their own theme inherit it.
func _apply_theme(node: Node) -> void:
	if node is Control and (node == dialog or node.theme != null):
		node.theme = ui_theme
	for child in node.get_children():
		_apply_theme(child)


func _setup_button(button: Button, label: String, action: Callable) -> void:
	if button.text == "" and button.icon == null:
		button.text = label
	button.focus_mode = Control.FOCUS_NONE # so Space/Enter keep advancing the dialog
	button.pressed.connect(action)


func _toggle_auto() -> void:
	auto_mode = not auto_mode
	auto_button.modulate = Color(1, 1, 0.6) if auto_mode else Color.WHITE
	if auto_mode and not typewriter.is_typing:
		_auto_advance()

## After a line finishes, waits and advances on its own. Stops at choices
## and at lines the mode keeps for the player (e.g. Ulyn's quiet scenes).
func _auto_advance() -> void:
	var entry := graph.get_entry(current_node)
	if not auto_mode or entry.has("choices") or not mode.auto_allowed(entry):
		return
	var serial := _node_serial
	var wait := auto_delay + text_label.get_parsed_text().length() * auto_delay_per_char
	await get_tree().create_timer(wait).timeout
	# Bail if the player moved on or turned Auto off; wait while the log or menu is open.
	while (dialog_log.visible or setting_menu.visible) and auto_mode and serial == _node_serial:
		await get_tree().process_frame
	if auto_mode and serial == _node_serial and not is_transitioning:
		_handle_advance()


## Everything needed to come back to this exact line later (see SaveGame).
func get_save_data() -> Dictionary:
	return {
		"scene": get_tree().current_scene.scene_file_path,
		"character": flow_graph_path.get_base_dir().get_file(),
		"node": current_node,
		"meters": mode.get_meters(),
		"flags": flags,
		"stage": stage.snapshot(),
		"amb": audio.current_amb(),
		"log": dialog_log.get_lines(),
	}

func _restore_save(data: Dictionary) -> void:
	# Saves from before modes existed only have "weight".
	mode.set_meters(data.get("meters", {"weight": data.get("weight", 55.0)}))
	flags = data.get("flags", {})
	mode.apply_effects(true)
	var lines : Array = data.get("log", [])
	dialog_log.set_lines(lines.slice(0, -1)) # process_node adds the current line back
	if data.get("amb", "") != "":
		audio.apply_amb({"amb": data["amb"]})

	current_node = data.get("node", start_node)
	if not graph.has_entry(current_node): # story was edited since this save
		push_warning("Save points to missing node '%s', starting over" % current_node)
		current_node = start_node
	is_transitioning = true
	await stage.restore(data.get("stage", {"backgrounds": [], "characters": {}}))
	process_node(current_node)


func _show_choices() -> void:
	var entry := graph.get_entry(current_node)
	if not entry.has("choices"):
		return

	var serial := _node_serial
	current_choices = filter_choices(entry["choices"])
	await get_tree().create_timer(choice_delay).timeout
	if serial != _node_serial: # moved on (e.g. rewound) while waiting
		return

	if entry.has("call"):
		phone.ring(entry["call"], current_choices)
		_start_choice_timer(mode.choice_time(entry))
		return

	choices_container.visible = true
	for i in choice_buttons.size():
		if i < current_choices.size():
			var c      = current_choices[i]
			var locked : bool = c.get("locked", false)
			choice_buttons[i].visible  = true
			choice_buttons[i].text     = c["text"]
			choice_buttons[i].disabled = locked #locked choices
			choice_buttons[i].modulate = Color(1, 1, 1, 0.35 if locked else 1.0)
		else:
			choice_buttons[i].visible = false
			choice_buttons[i].text    = ""

	_start_choice_timer(mode.choice_time(entry))


## Shows a bar above the top choice that empties over `seconds`.
func _start_choice_timer(seconds: float) -> void:
	_choice_time = seconds
	_choice_time_left = seconds
	timer_bar.visible = seconds > 0.0 and not phone.visible
	if seconds <= 0.0 or phone.visible:
		return
	var top : Control = null
	for b in choice_buttons:
		if b.visible and (top == null or b.position.y < top.position.y):
			top = b
	timer_bar.position = top.position - Vector2(0, TIMER_BAR_HEIGHT * 3)
	timer_bar.size = Vector2(top.size.x, TIMER_BAR_HEIGHT)
	timer_bar.pivot_offset = Vector2(top.size.x / 2.0, 0)
	timer_bar.scale.x = 1.0

func _tick_choice_timer(delta: float) -> void:
	if _choice_time <= 0.0 or not (choices_container.visible or phone.visible):
		return
	if dialog_log.visible or setting_menu.visible:
		return # paused while reading the log or in the menu
	_choice_time_left -= delta
	timer_bar.scale.x = maxf(_choice_time_left / _choice_time, 0.0)
	phone.set_progress(_choice_time_left / _choice_time)
	if _choice_time_left <= 0.0:
		select_choice(mode.timeout_choice(current_choices))


func _on_choice_pressed(index: int) -> void:
	if index >= current_choices.size() or current_choices[index].get("locked", false):
		return
	select_choice(current_choices[index])


func select_choice(choice: Dictionary) -> void:
	choices_container.visible = false
	phone.hang_up()
	_choice_time = 0.0
	timer_bar.visible = false
	dialog_log.add_choice(choice.get("text", ""))
	_push_history(current_node, true)  #block rewind past
	mode.apply_choice(choice)
	mode.apply_effects()
	if choice.has("set_flag"):
		flags[choice["set_flag"]] = true
	current_node = choice["next"]
	process_node(current_node)

## Locks choices the mode says are locked, and hides choices whose
## "requires" flag hasn't been set (e.g. a detail that wasn't noticed).
func filter_choices(choices: Array) -> Array:
	var filtered := []
	for choice in choices:
		if choice.has("requires") and not flags.get(choice["requires"], false):
			continue
		var c = choice.duplicate()
		c["locked"] = mode.is_locked(choice)
		filtered.append(c)
	return filtered



func apply_emotion(emotion: String) -> void:
	emotion_multiplier = EMOTION_MULTIPLIERS.get(emotion, 1.0)
	update_typing_speed()

func update_typing_speed() -> void:
	typewriter.speed = BASE_TYPING_SPEED * emotion_multiplier * mode.speed_multiplier() * _line_speed


# --- Noticing: {shown text|FlagName} in a line is a detail the player can click ---

## Story text -> BBCode for the dialog: unnoticed details are links.
func _render(text: String) -> String:
	var out := text.replace("[", "[lb]")
	for m in _notice_regex.search_all(text):
		var flag := m.get_string(2)
		var color := notice_color
		var shown := m.get_string(1)
		if flags.get(flag, false):
			color.a = NOTICED_ALPHA
			out = out.replace(m.get_string(), "[color=#%s]%s[/color]" % [color.to_html(), shown])
		else:
			out = out.replace(m.get_string(), "[url=%s][color=#%s]%s[/color][/url]" % [flag, color.to_html(), shown])
	return out

## Story text -> plain text (for the log).
func _plain(text: String) -> String:
	return _notice_regex.sub(text, "$1", true)

func _on_notice_clicked(meta: Variant) -> void:
	var flag := str(meta)
	if flags.get(flag, false):
		return
	flags[flag] = true
	_hovered_notice = ""
	# Redraw the line so the detail shows as noticed, keeping the typing progress.
	var shown := text_label.visible_characters
	var line_text : String = _current_line.get("text", "")
	if typewriter.is_typing and _current_line.has("unsaid"):
		return # mid self-edit: it'll show as noticed next time
	text_label.text = _render(line_text).strip_edges()
	text_label.visible_characters = shown
	_flash_noticed()

func _flash_noticed() -> void:
	var tag := Label.new()
	tag.text = "noticed"
	tag.add_theme_color_override("font_color", notice_color)
	tag.position = text_label.global_position + Vector2(text_label.size.x - 120, -36)
	tag.modulate.a = 0.0
	dialog.add_child(tag)
	var t := create_tween()
	t.tween_property(tag, "modulate:a", 1.0, 0.2)
	t.tween_interval(0.8)
	t.tween_property(tag, "modulate:a", 0.0, 0.5)
	t.tween_callback(tag.queue_free)



## Warns about names in the flow graph that the scene doesn't have, and keys
## the character's mode doesn't understand (see StoryMode.info()).
func _validate() -> void:
	for problem in graph.find_broken_links():
		push_warning(problem)

	var info := mode.info()
	var mode_name : String = mode.get_script().get_global_name()
	var node_keys : Array = StoryMode.BASE_NODE_KEYS + info.get("node_keys", [])
	var choice_keys : Array = StoryMode.BASE_CHOICE_KEYS + info.get("choice_keys", [])
	var choice_types : Array = info.get("choice_types", [])
	var meters : Dictionary = info.get("meters", {})
	for problem in mode.validate(graph):
		push_warning(problem)

	# Flags anything can set: choices, and details to notice.
	var flags_set := {}
	for id in graph.nodes:
		var entry : Dictionary = graph.nodes[id]
		for choice in entry.get("choices", []):
			if choice.has("set_flag"):
				flags_set[choice["set_flag"]] = true
		for m in _notice_regex.search_all(String(entry.get("text", ""))):
			flags_set[m.get_string(2)] = true

	for id in graph.nodes:
		var entry : Dictionary = graph.nodes[id]
		for key in entry:
			if key not in node_keys:
				push_warning("Node %s: '%s' isn't used by %s" % [id, key, mode_name])
		for choice in entry.get("choices", []):
			for key in choice:
				if key not in choice_keys:
					push_warning("Node %s: choice key '%s' isn't used by %s" % [id, key, mode_name])
			if choice_types and choice.get("type", "") not in choice_types:
				push_warning("Node %s: choice type '%s' isn't one of %s" % [id, choice.get("type", ""), choice_types])
		for choice in entry.get("choices", []):
			if choice.has("requires") and choice["requires"] not in flags_set:
				push_warning("Node %s: choice requires '%s', but nothing sets that flag (no choice or {detail|%s})" % [id, choice["requires"], choice["requires"]])
		if entry.has("call") and entry.get("choices", []).is_empty():
			push_warning("Node %s: a call needs choices (e.g. Decline / Answer)" % id)
		var condition : String = entry.get("secret", {}).get("condition", "")
		if condition.ends_with("_above") or condition.ends_with("_below"):
			var meter := condition.trim_suffix("_above").trim_suffix("_below")
			if not meters.has(meter):
				push_warning("Node %s: secret uses '%s', but %s has no '%s' meter" % [id, condition, mode_name, meter])
		var bg : String = entry.get("background", "")
		if bg != "" and not stage.has_background(bg):
			push_warning("Node %s: no background named '%s' under Bgs" % [id, bg])
		for char_name in entry.get("show_characters", []) + entry.get("hide_characters", []):
			if not stage.has_character(char_name):
				push_warning("Node %s: no character named '%s' under Characters" % [id, char_name])
		var expressions : Dictionary = entry.get("expression", {})
		for char_name in expressions:
			if not stage.has_expression(char_name, expressions[char_name]):
				push_warning("Node %s: %s has no animation '%s'" % [id, char_name, expressions[char_name]])
		if entry.has("sfx") and not audio.has_sfx(entry["sfx"]):
			push_warning("Node %s: unknown sfx '%s'" % [id, entry["sfx"]])
		if entry.has("voice") and not audio.has_voice(entry["voice"]):
			push_warning("Node %s: unknown voice '%s'" % [id, entry["voice"]])
		if entry.has("amb") and not audio.has_amb(entry["amb"]):
			push_warning("Node %s: unknown amb '%s'" % [id, entry["amb"]])
		if entry.get("choices", []).size() > choice_buttons.size():
			push_warning("Node %s has more choices than buttons" % id)
