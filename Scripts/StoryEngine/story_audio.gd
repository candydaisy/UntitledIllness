class_name StoryAudio
extends RefCounted
## Sound effects and ambience shared by every character's story.
## Add new sounds to SFX / AMB and use their names in a flow graph.

const SFX_VOLUME_DB := -10.0
const AMB_VOLUME_DB := -18.0
const SILENT_DB     := -80.0
const FADE_TIME     := 0.6

const SFX := {
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
	"Inhale": preload("res://Assets/audio/sfx/inhale.ogg"),
}

const AMB := {
	"Bedroom": preload("res://Assets/audio/amb/1.wav"),
	#"SchoolChatter": preload(""),
	#"Class": preload(""),
	#"Cafeteria": preload(""),
	#"Road": preload(""),
	#"school":  preload("")
}

var host : Node # creates the tweens
var sfx_player : AudioStreamPlayer
var amb_player : AudioStreamPlayer

var _fades := {} # AudioStreamPlayer -> Tween


func _init(host_node: Node, sfx: AudioStreamPlayer, amb: AudioStreamPlayer) -> void:
	host = host_node
	sfx_player = sfx
	amb_player = amb


func has_sfx(sfx_name: String) -> bool:
	return sfx_name == "stop" or SFX.has(sfx_name)

func has_amb(amb_name: String) -> bool:
	return amb_name == "stop" or AMB.has(amb_name)


## Applies a node's "sfx" key: a sound name, or "stop" to fade it out.
func apply_sfx(entry: Dictionary) -> void:
	if not entry.has("sfx"):
		return
	var sfx_name : String = entry["sfx"]
	if sfx_name == "stop":
		_fade_out_and_stop(sfx_player)
		return
	if not SFX.has(sfx_name):
		push_warning("Unknown sfx: " + sfx_name)
		return
	_kill_fade(sfx_player)
	sfx_player.stream    = SFX[sfx_name]
	sfx_player.volume_db = SFX_VOLUME_DB
	sfx_player.play()


## Applies a node's "amb" key: crossfades to a new loop, or "stop".
func apply_amb(entry: Dictionary) -> void:
	if not entry.has("amb"):
		return
	var amb_name : String = entry["amb"]
	if amb_name == "stop":
		_fade_out_and_stop(amb_player)
		return
	if not AMB.has(amb_name):
		push_warning("Unknown amb: " + amb_name)
		return
	var stream : AudioStream = AMB[amb_name]
	if amb_player.stream == stream and amb_player.playing:
		return

	var t := _new_fade(amb_player)
	if amb_player.playing:
		t.tween_property(amb_player, "volume_db", SILENT_DB, FADE_TIME)
	t.tween_callback(_start_amb.bind(stream))
	t.tween_property(amb_player, "volume_db", AMB_VOLUME_DB, FADE_TIME)


func _start_amb(stream: AudioStream) -> void:
	amb_player.stream    = stream
	amb_player.volume_db = SILENT_DB
	amb_player.play()

func _fade_out_and_stop(player: AudioStreamPlayer) -> void:
	if not player.playing:
		return
	var t := _new_fade(player)
	t.tween_property(player, "volume_db", SILENT_DB, FADE_TIME)
	t.tween_callback(player.stop)

func _new_fade(player: AudioStreamPlayer) -> Tween:
	_kill_fade(player)
	var t := host.create_tween()
	_fades[player] = t
	return t

## Cancels a running fade so it can't stop a sound that started after it.
func _kill_fade(player: AudioStreamPlayer) -> void:
	var t : Tween = _fades.get(player)
	if t and t.is_valid():
		t.kill()
