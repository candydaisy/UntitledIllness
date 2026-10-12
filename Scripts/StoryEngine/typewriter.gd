class_name Typewriter
extends RefCounted
## Reveals a RichTextLabel one character at a time, with typing sounds and
## short pauses after punctuation. Call tick() every frame.
## start_edit() types one line, deletes it, then types another (self-editing),
## or with instant = true breaks it off and switches straight to the other.

signal finished

const PAUSE_DURATIONS := { ",": 0.15, ".": 0.35, "!": 0.35, "?": 0.35 }
const SILENT_CHARS    := [" ", ",", ".", "!", "?"]
const EDIT_HOLD   := 0.6 # pause on the unsaid line before deleting it
const DELETE_MULT := 2.5 # deleting is faster than typing

enum Phase { IDLE, TYPING, HOLD, DELETING }

var label : RichTextLabel
var sound : AudioStreamPlayer
var speed := 30.0 # characters per second
var sound_volume_db := -21.0
var is_typing := false

var _text := "" # text without BBCode, matches visible_characters
var _final_text := "" # what's typed after the unsaid line is deleted
var _instant := false # switch to _final_text without deleting
var _phase := Phase.IDLE
var _progress := 0.0
var _pause := 0.0


func _init(target: RichTextLabel, type_sound: AudioStreamPlayer) -> void:
	label = target
	sound = type_sound


func start(text: String) -> void:
	_final_text = ""
	_begin(text)

## Types `unsaid`, holds, deletes it, then types `text`. With instant = true
## it's cut off instead: after the hold, `text` replaces it straight away.
func start_edit(unsaid: String, text: String, instant := false) -> void:
	_final_text = text
	_instant = instant
	_begin(unsaid)

func skip() -> void:
	if not is_typing:
		return
	if _final_text != "":
		label.text = _final_text.strip_edges()
		_text = label.get_parsed_text()
		_final_text = ""
	_finish()

## Stops without emitting finished (used when leaving the line early).
func stop() -> void:
	is_typing = false
	_phase = Phase.IDLE
	_pause = 0.0


func tick(delta: float) -> void:
	if not is_typing:
		return

	if _pause > 0.0:
		_pause -= delta
		return

	match _phase:
		Phase.HOLD:
			if _instant:
				var next := _final_text
				_final_text = ""
				_begin(next)
			else:
				_phase = Phase.DELETING
				_progress = label.visible_characters
		Phase.DELETING:
			_tick_delete(delta)
		Phase.TYPING:
			_tick_type(delta)


func _begin(text: String) -> void:
	label.text = text.strip_edges()
	_text = label.get_parsed_text()
	label.visible_characters = 0
	_progress = 0.0
	_pause = 0.0
	_phase = Phase.TYPING
	is_typing = true

func _tick_type(delta: float) -> void:
	_progress += speed * delta
	var target := mini(int(_progress), _text.length())
	var play_sound := false

	# A slow frame can reveal several characters; stop early at punctuation.
	while label.visible_characters < target:
		var ch := _text[label.visible_characters]
		label.visible_characters += 1
		if ch not in SILENT_CHARS:
			play_sound = true
		if ch in PAUSE_DURATIONS:
			_pause = PAUSE_DURATIONS[ch]
			_progress = label.visible_characters
			break

	if play_sound:
		_play_sound()

	if label.visible_characters >= _text.length():
		if _final_text != "":
			_phase = Phase.HOLD
			_pause = EDIT_HOLD
		else:
			_finish()

func _tick_delete(delta: float) -> void:
	var before := label.visible_characters
	_progress -= speed * DELETE_MULT * delta
	label.visible_characters = maxi(int(_progress), 0)
	if label.visible_characters < before:
		_play_sound()
	if label.visible_characters == 0:
		var next := _final_text
		_final_text = ""
		_begin(next)


func _finish() -> void:
	label.visible_characters = _text.length()
	is_typing = false
	_phase = Phase.IDLE
	_pause = 0.0
	finished.emit()

func _play_sound() -> void:
	sound.volume_db   = sound_volume_db
	sound.pitch_scale = randf_range(1.30, 1.50)
	sound.play()
