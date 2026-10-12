class_name StoryPlayer
extends Node2D
## Plays a character's story from a flow graph JSON.
## Reuse this script for every character's story scene: set flow_graph_path
## (and the other exports) in the Inspector. The scene needs the same node
## layout as Story.tscn: Bgs, Characters, Audio and Cenfix/Dialog.

@export_file("*.json") var flow_graph_path := "res://Story/Kay/flow_graph.json"
@export_file("*.tscn") var end_scene_path := "res://Scenes/Menus/title_menu.tscn" # when story ends
@export var start_node := "1"
@export var starting_weight := 55.0
@export var max_weight := 100.0
@export var choice_delay := 1.5
@export var auto_delay := 1.2 # seconds Auto waits after a line finishes...
@export var auto_delay_per_char := 0.03 # ...plus this per character, so long lines stay up longer
@export var debug_log := false # print node / weight / state on every node

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

const WEIGHT_MODULATE := [
	Color(1.0,  1.0,  1.0 ), # LOW
	Color(0.9,  0.9,  0.9 ), # MEDIUM
	Color(0.75, 0.75, 0.75), # HIGH
	Color(0.6,  0.6,  0.6 ), # CRITICAL
]

const WEIGHT_SPEED_MULT := [1.0, 0.9, 0.7, 0.5]
const WEIGHT_VOLUME_DB  := [-21.0, -19.0, -17.0, -14.0] #typing sound Db.
const WEIGHT_TINT_TIME  := 0.8


var graph : FlowGraph
var weight : EmotionalWeight
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

var _node_serial := 0 # bumped on every node change so stale awaits can bail out
var _tint_tween : Tween



func _ready() -> void:
	choices_container.visible = false  # Hide choices

	graph = FlowGraph.load_from(flow_graph_path)
	if graph == null:
		return

	weight     = EmotionalWeight.new(starting_weight, max_weight)
	typewriter = Typewriter.new(text_label, type_sound)
	stage      = StoryStage.new(self, bgs_container, characters_container)
	audio      = StoryAudio.new(self, sfx_player, amb_player, voice_player)
	world_tint = CanvasModulate.new()
	add_child(world_tint)

	weight.state_changed.connect(_on_weight_state_changed)
	typewriter.finished.connect(_show_choices)
	typewriter.finished.connect(_auto_advance)
	for i in choice_buttons.size():
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

	dialog_log = DialogLog.new(dialog.get_node("DialogBox"))
	dialog.add_child(dialog_log)
	_setup_button(auto_button, "Auto", _toggle_auto)
	_setup_button(log_button, "Log", dialog_log.toggle)
	_setup_button(menu_button, "Menu", setting_menu.open)
	setting_menu.visible = false

	if OS.is_debug_build():
		_validate()

	if not SaveGame.pending.is_empty():
		var data := SaveGame.pending
		SaveGame.pending = {}
		_restore_save(data)
		return

	_apply_weight_effects(true)
	current_node = start_node
	process_node(current_node)


func _process(delta: float) -> void:
	if typewriter:
		typewriter.tick(delta)


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
	# Clicking Auto, Log or a choice shouldn't also advance the dialog.
	if event is InputEventMouseButton and get_viewport().gui_get_hovered_control() is BaseButton:
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
	dialog_log.remove_last(2) # this line, and the one about to be shown again

	var s = node_history.pop_back()
	current_node = s["node"]
	flags = s["flags"]
	emotion_multiplier = s["emotion_multiplier"]
	weight.set_value(s["weight"])

	is_transitioning = true
	await stage.restore(s["stage"])
	process_node(current_node)


func _handle_advance() -> void:
	if typewriter.is_typing:
		typewriter.skip()
		return

	var entry := graph.get_entry(current_node)
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
		"weight":weight.value,
		"emotion_multiplier":emotion_multiplier,
		"from_choice":from_choice,
		"flags":flags.duplicate(),
		"stage":stage.snapshot(),
	})



func process_node(node_name: String) -> void:
	_node_serial += 1
	var serial := _node_serial
	choices_container.visible = false

	if not graph.has_entry(node_name):
		push_error("Flow graph has no node: " + node_name)
		return
	var entry := graph.get_entry(node_name)

	is_transitioning = true
	pending_secret = graph.secret_target(entry, weight.value, flags)
	audio.apply_amb(entry)
	await stage.apply(entry)
	if serial != _node_serial:
		return
	is_transitioning = false

	audio.apply_sfx(entry)
	audio.apply_voice(entry)
	speaker_label.text = entry.get("speaker", "")
	apply_emotion(entry.get("emotion", ""))
	typewriter.start(entry.get("text", ""))
	dialog_log.add_line(speaker_label.text, text_label.get_parsed_text())

	if debug_log:
		print("node ", node_name, " | weight ", weight.value, " | ", EmotionalWeight.State.keys()[weight.state])



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

## After a line finishes, waits and advances on its own. Stops at choices.
func _auto_advance() -> void:
	if not auto_mode or graph.get_entry(current_node).has("choices"):
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
		"weight": weight.value,
		"flags": flags,
		"stage": stage.snapshot(),
		"amb": audio.current_amb(),
		"log": dialog_log.get_lines(),
	}

func _restore_save(data: Dictionary) -> void:
	weight.set_value(data.get("weight", starting_weight))
	flags = data.get("flags", {})
	_apply_weight_effects(true)
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


func _on_choice_pressed(index: int) -> void:
	if index >= current_choices.size() or current_choices[index].get("locked", false):
		return
	select_choice(current_choices[index])


func select_choice(choice: Dictionary) -> void:
	choices_container.visible = false
	dialog_log.add_choice(choice.get("text", ""))
	_push_history(current_node, true)  #block rewind past
	weight.change(choice.get("weight_change", 0.0))
	if choice.has("set_flag"):
		flags[choice["set_flag"]] = true
	current_node = choice["next"]
	process_node(current_node)

func filter_choices(choices: Array) -> Array:
	var filtered := []
	for choice in choices:
		var c = choice.duplicate()
		c["locked"] = (choice.get("type", "") == "helpful" and weight.state >= EmotionalWeight.State.CRITICAL)
		filtered.append(c)
	return filtered



func _on_weight_state_changed(_state: EmotionalWeight.State) -> void:
	_apply_weight_effects()

func _apply_weight_effects(instant := false) -> void:
	var color : Color = WEIGHT_MODULATE[weight.state]
	if _tint_tween and _tint_tween.is_valid():
		_tint_tween.kill()
	if instant:
		world_tint.color = color
	else:
		_tint_tween = create_tween()
		_tint_tween.tween_property(world_tint, "color", color, WEIGHT_TINT_TIME)
	typewriter.sound_volume_db = WEIGHT_VOLUME_DB[weight.state]
	update_typing_speed()


func apply_emotion(emotion: String) -> void:
	emotion_multiplier = EMOTION_MULTIPLIERS.get(emotion, 1.0)
	update_typing_speed()

func update_typing_speed() -> void:
	typewriter.speed = BASE_TYPING_SPEED * emotion_multiplier * WEIGHT_SPEED_MULT[weight.state]



## Warns about names in the flow graph that the scene doesn't have.
func _validate() -> void:
	for problem in graph.find_broken_links():
		push_warning(problem)

	for id in graph.nodes:
		var entry : Dictionary = graph.nodes[id]
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
