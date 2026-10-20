class_name KayMode
extends StoryMode
## Kay: one Emotional Weight meter. As it rises the world turns grey, his text
## slows down, and at CRITICAL helpful choices lock.

@export var starting_weight := 55.0
@export var max_weight := 100.0

const WEIGHT_MODULATE := [
	Color(1.0,  1.0,  1.0 ), # LOW
	Color(0.75, 0.75, 0.75), # MEDIUM
	Color(0.52,  0.52, 0.52 ), # HIGH
	Color(0.32,  0.32, 0.32 ), # CRITICAL
]

const WEIGHT_SPEED_MULT := [1.0, 0.9, 0.7, 0.5]
const WEIGHT_VOLUME_DB  := [-21.0, -19.0, -17.0, -14.0] #typing sound Db.
const WEIGHT_TINT_TIME  := 0.8

const INFO := {
	"meters": {
		"weight": "Emotional Weight, 0-100. LOW < 30, MEDIUM < 50, HIGH < 80, CRITICAL 80+.",
	},
	"features": [
		"Dimmed: the world fades to grey as weight rises.",
		"Slow text: typing slows down and the typing sound gets louder.",
		"Locked help: helpful choices lock at CRITICAL.",
	],
	"node_keys": [],
	"choice_keys": ["weight_change"],
	"choice_types": ["neutral", "honest", "helpful"],
}

var weight : EmotionalWeight
var _tint_tween : Tween


func setup(story_player: StoryPlayer) -> void:
	super(story_player)
	weight = EmotionalWeight.new(starting_weight, max_weight)
	weight.state_changed.connect(func(_state): apply_effects())


func info() -> Dictionary:
	return INFO


func get_meters() -> Dictionary:
	return {"weight": weight.value}

func set_meters(meters: Dictionary) -> void:
	weight.set_value(meters.get("weight", starting_weight))


func apply_choice(choice: Dictionary) -> void:
	weight.change(choice.get("weight_change", 0.0))

func is_locked(choice: Dictionary) -> bool:
	return choice.get("type", "") == "helpful" and weight.state >= EmotionalWeight.State.CRITICAL


func speed_multiplier() -> float:
	return WEIGHT_SPEED_MULT[weight.state]

func apply_effects(instant := false) -> void:
	var color : Color = WEIGHT_MODULATE[weight.state]
	if _tint_tween and _tint_tween.is_valid():
		_tint_tween.kill()
	if instant:
		player.world_tint.color = color
	else:
		_tint_tween = player.create_tween()
		_tint_tween.tween_property(player.world_tint, "color", color, WEIGHT_TINT_TIME)
	player.typewriter.sound_volume_db = WEIGHT_VOLUME_DB[weight.state]
	player.update_typing_speed()


func describe() -> String:
	return "weight %s | %s" % [weight.value, EmotionalWeight.State.keys()[weight.state]]
