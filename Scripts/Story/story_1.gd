extends Node2D

@onready var type_sound : AudioStreamPlayer = $Audio/typing
@onready var sfx_player : AudioStreamPlayer = $Audio/sfx
@onready var amb_player : AudioStreamPlayer = $Audio/amb #looping
@onready var characters_container : Node = $Characters
@onready var bgs_container : Node = $Bgs
@onready var dialog := $Cenfix/Dialog #dialog panel
@onready var speaker_label : Label = dialog.speaker
@onready var text_label : RichTextLabel = dialog.dialog_line #dialog text
@onready var choices_container : Control = $Cenfix/Dialog/Choices
@onready var choice_buttons := [
	$Cenfix/Dialog/Choices/choice1,
	$Cenfix/Dialog/Choices/choice2,
	$Cenfix/Dialog/Choices/choice3,
]


const FLOW_GRAPH_PATH   := "res://Assets/Script-story/K/flow_graph.json"

const MENU_SCENE_PATH   := "res://Scenes/title_menu.tscn" # when story ends

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

const SFX_VOLUME_DB     := -10.0
const AMB_VOLUME_DB     := -18.0

const PAUSE_DURATIONS   := { ",": 0.15, ".": 0.35, "!": 0.35, "?": 0.35 }
const PUNCTUATION       := [" ", ",", ".", "!", "?"]



var current_node := "1"
var typing_speed := BASE_TYPING_SPEED
var typing_progress := 0.0
var current_text := ""
var is_typing := false
var pause_timer := 0.0
var emotion_multiplier := 1.0
var emotional_weight := 55.0
var max_weight := 100.0
var flags := {} # (key: String - bool)
var is_transitioning := false
var current_choices := []
var node_history : Array = []
var pending_secret := ""

enum WeightState { LOW, MEDIUM, HIGH, CRITICAL }
var current_weight_state := WeightState.MEDIUM

# AUDIO LIBRARY

var sound_library := {
	"sfx": {
		"Alarm": preload("res://Assets/audio/sfx/alarm.ogg"),
		"Bednoises": preload("res://Assets/audio/sfx/bednoicecs.ogg"),
		"Shower": preload("res://Assets/audio/sfx/shower.ogg"),
		"Walkingstep": preload("res://Assets/audio/sfx/waliking.ogg"),
		"Softpat": preload("res://Assets/audio/sfx/pat.ogg"),
		"Sigh": preload("res://Assets/audio/sfx/sigh.ogg"),
		"Waterspraying": preload("res://Assets/audio/sfx/plantwatering.ogg"),
		"Pageturning": preload("res://Assets/audio/sfx/pageturn.ogg"),
		"Writing": preload("res://Assets/audio/sfx/writing.ogg"),
		"Notification": preload("res://Assets/audio/sfx/notification.ogg"),
		"Scrolls": preload("res://Assets/audio/sfx/scroll.ogg"),
		"Bodyfallonbed": preload("res://Assets/audio/sfx/jumpingonbed.ogg"),
		"Inhale": preload("res://Assets/audio/sfx/inhale.ogg")
	},
	"amb": {
		"Bedroom": preload("res://Assets/audio/amb/1.wav"),
		#"SchoolChatter": preload(""),
		#"Class": preload(""),
		#"Cafeteria": preload(""),
		#"Road": preload(""),
		#"school":  preload("")
	}
}



var flow_graph : Dictionary = {}

func _load_flow_graph() -> void:
	var file = FileAccess.open(FLOW_GRAPH_PATH, FileAccess.READ)
	if file == null:
		push_error("flow_graph.json not found at: " + FLOW_GRAPH_PATH)
		return
	var json = JSON.new()
	var err  = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Failed to parse flow_graph.json: " + json.get_error_message())
		return
	flow_graph = json.get_data()



func _ready() -> void:
	_load_flow_graph()
	choices_container.visible = false  # Hide choices

	for i in choice_buttons.size():
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

	process_node(current_node)



func _input(event: InputEvent) -> void:
	if event.is_echo() or is_transitioning:
		return

	if event.is_action_pressed("dialog_deprocess"):
		_handle_rewind()
	elif event.is_action_pressed("dialog_process"):
		_handle_advance()


func _handle_rewind() -> void:
	if node_history.is_empty() or node_history.back().get("from_choice", false):
		return

	is_typing  = false
	pause_timer = 0.0
	pending_secret = ""
	choices_container.visible = false

	var s = node_history.pop_back()
	current_node = s["node"]
	emotional_weight = s["weight"]
	emotion_multiplier = s["emotion_multiplier"]
	flags = s["flags"]
	update_weight_state()
	process_node(current_node)


func _handle_advance() -> void:
	if is_typing:
		text_label.visible_characters = current_text.length()
		is_typing   = false
		pause_timer = 0.0
		check_for_choices()
		return

	var entry = flow_graph[current_node]
	if entry.has("choices"):
		return
	if not entry.has("next") and pending_secret == "":
		get_tree().change_scene_to_file(MENU_SCENE_PATH)
		return

	_push_history(current_node)
	current_node = pending_secret if pending_secret != "" else entry["next"]
	pending_secret = ""
	process_node(current_node)
	update_weight_state()


func _push_history(node: String, from_choice := false) -> void:
	node_history.append({
		"node":node,
		"weight":emotional_weight,
		"emotion_multiplier":emotion_multiplier,
		"from_choice":from_choice,
		"flags":flags.duplicate(),
	})



func process_node(node_name: String) -> void:
	choices_container.visible = false
	
	if not flow_graph.has(node_name):
		return

	var entry  = flow_graph[node_name]

	pending_secret = check_secret(entry)

	await apply_visuals(entry)

	_apply_sfx(entry)

	speaker_label.text = entry.get("speaker", "")
	apply_emotion(entry.get("emotion", ""))
	start_typing(entry.get("text", ""))

	print(emotional_weight, " | ", current_weight_state, " | ", WeightState)  #debug



func check_secret(entry: Dictionary) -> String:
	if not entry.has("secret"):
		return ""

	var secret = entry["secret"]
	var condition = secret.get("condition", "")
	var met: bool

	match condition:
		"weight_above":	met = emotional_weight > secret.get("value", 0)
		"weight_below":	met = emotional_weight < secret.get("value", 0)
		"flag_true":met = flags.get(secret.get("flag", ""), false)
		"flag_false":met = not flags.get(secret.get("flag", ""), false)
		_:met = false

	return secret.get("next", "") if met else ""



func start_typing(text: String) -> void:
	current_text = text.strip_edges()
	text_label.text = current_text
	text_label.visible_characters = 0
	typing_progress = 0.0
	pause_timer = 0.0
	is_typing = true



func _process(delta: float) -> void:
	if not is_typing:
		return

	if pause_timer > 0.0:
		pause_timer -= delta
		return

	typing_progress += typing_speed * delta
	var next_visible := int(typing_progress)

	if next_visible > text_label.visible_characters:
		text_label.visible_characters = next_visible

		if next_visible <= current_text.length():
			var ch := current_text[next_visible - 1]

			if ch not in PUNCTUATION:
				play_type_sound()

			if ch in PAUSE_DURATIONS:
				pause_timer = PAUSE_DURATIONS[ch]

	if text_label.visible_characters >= current_text.length():
		text_label.visible_characters = current_text.length()
		is_typing = false
		check_for_choices()



func check_for_choices() -> void:
	var entry = flow_graph[current_node]
	if not entry.has("choices"):
		return

	current_choices = filter_choices(entry["choices"])
	await get_tree().create_timer(1.5).timeout

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
	change_weight(choice["weight_change"])
	if choice.has("set_flag"):
		flags[choice["set_flag"]] = true
	_push_history(current_node, true)  #block rewind past
	current_node = choice["next"]
	process_node(current_node)

func filter_choices(choices: Array) -> Array:
	var filtered := []
	for choice in choices:
		var c      = choice.duplicate()
		var type   = choice["type"]
		c["locked"] = (type == "helpful" and current_weight_state >= WeightState.CRITICAL)
		filtered.append(c)
	return filtered



func change_weight(amount: float) -> void:
	emotional_weight = clamp(emotional_weight + amount, 0.0, max_weight)
	update_weight_state()

func update_weight_state() -> void:
	var percent := emotional_weight / max_weight
	if percent < 0.30:
		current_weight_state = WeightState.LOW
	elif percent < 0.50:
		current_weight_state = WeightState.MEDIUM
	elif percent < 0.80:
		current_weight_state = WeightState.HIGH
	else:
		current_weight_state = WeightState.CRITICAL
	apply_world_effects()

func apply_world_effects() -> void:
	modulate = WEIGHT_MODULATE[current_weight_state]
	update_typing_speed()



func apply_emotion(emotion: String) -> void:
	emotion_multiplier = EMOTION_MULTIPLIERS.get(emotion, 1.0)
	update_typing_speed()

func update_typing_speed() -> void:
	typing_speed = BASE_TYPING_SPEED * emotion_multiplier * WEIGHT_SPEED_MULT[current_weight_state]



func play_type_sound() -> void:
	type_sound.volume_db   = WEIGHT_VOLUME_DB[current_weight_state]
	type_sound.pitch_scale = randf_range(1.30, 1.50) 
	type_sound.play()



func apply_visuals(entry: Dictionary) -> void:
	is_transitioning = true
	
	if entry.has("background"):
		for bg in bgs_container.get_children():
			if bg.name == entry["background"]:
				if not bg.visible:
					bg.modulate.a = 0.0
					bg.visible = true
					_fade_node(bg, 1.0)
			elif bg.visible:
				await _fade_node(bg, 0.0)
				bg.visible = false

	if entry.has("show_characters"):
		for char_name in entry["show_characters"]:
			var n = characters_container.get_node_or_null(char_name)
			if n and not n.visible:
				n.modulate.a = 0.0
				n.visible    = true
				_fade_node(n, 1.0)

	if entry.has("hide_characters"):
		for char_name in entry["hide_characters"]:
			var n = characters_container.get_node_or_null(char_name)
			if n and n.visible:
				await _fade_node(n, 0.0)
				n.visible = false

	if entry.has("expression"):
		for char_name in entry["expression"]:
			var n = characters_container.get_node_or_null(char_name)
			if n:
				n.play(entry["expression"][char_name])


	if entry.has("amb"):
		var amb_name = entry["amb"]
		if amb_name == "stop":
			await _fade_audio(amb_player, -80.0)
			amb_player.stop()
		else:
			var stream = sound_library["amb"].get(amb_name)
			if stream and amb_player.stream != stream:
				await _fade_audio(amb_player, -80.0)
				amb_player.stream    = stream
				amb_player.volume_db = -80.0
				amb_player.play()
				_fade_audio(amb_player, AMB_VOLUME_DB)
	is_transitioning = false


func _apply_sfx(entry: Dictionary) -> void:
	if not entry.has("sfx"):
		return
	var sfx_name = entry["sfx"]
	if sfx_name == "stop":
		await _fade_audio(sfx_player, -80.0)
		sfx_player.stop()
		return
	var stream = sound_library["sfx"].get(sfx_name)
	if stream:
		sfx_player.stream    = stream
		sfx_player.volume_db = SFX_VOLUME_DB
		sfx_player.play()
		print(sound_library["sfx"].get(sfx_name))
		"sfx_player.volume_db = -80.0
		sfx_player.play()
		_fade_audio(sfx_player, SFX_VOLUME_DB)"


func _fade_node(node: CanvasItem, target_alpha: float) -> void:	
	var t = create_tween()
	t.tween_property(node, "modulate:a", target_alpha, 0.67) 
	await t.finished

func _fade_audio(player: AudioStreamPlayer, target_db: float) -> void:
	var t = create_tween()
	t.tween_property(player, "volume_db", target_db, 0.6)
	await t.finished
