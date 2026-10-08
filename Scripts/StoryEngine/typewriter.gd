class_name Typewriter
extends RefCounted
## Reveals a RichTextLabel one character at a time, with typing sounds and
## short pauses after punctuation. Call tick() every frame.

signal finished

const PAUSE_DURATIONS := { ",": 0.15, ".": 0.35, "!": 0.35, "?": 0.35 }
const SILENT_CHARS    := [" ", ",", ".", "!", "?"]

var label : RichTextLabel
var sound : AudioStreamPlayer
var speed := 30.0 # characters per second
var sound_volume_db := -21.0
var is_typing := false

var _text := "" # text without BBCode, matches visible_characters
var _progress := 0.0
var _pause := 0.0


func _init(target: RichTextLabel, type_sound: AudioStreamPlayer) -> void:
	label = target
	sound = type_sound


func start(text: String) -> void:
	label.text = text.strip_edges()
	_text = label.get_parsed_text()
	label.visible_characters = 0
	_progress = 0.0
	_pause = 0.0
	is_typing = true

func skip() -> void:
	if is_typing:
		_finish()

## Stops without emitting finished (used when leaving the line early).
func stop() -> void:
	is_typing = false
	_pause = 0.0


func tick(delta: float) -> void:
	if not is_typing:
		return

	if _pause > 0.0:
		_pause -= delta
		return

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
		_finish()


func _finish() -> void:
	label.visible_characters = _text.length()
	is_typing = false
	_pause = 0.0
	finished.emit()

func _play_sound() -> void:
	sound.volume_db   = sound_volume_db
	sound.pitch_scale = randf_range(1.30, 1.50)
	sound.play()
