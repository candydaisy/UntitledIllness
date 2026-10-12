class_name ElysiaMode
extends StoryMode
## Elysia: two hidden meters.
##   mask   - how much she's performing "the version". Performing raises it.
##   energy - what it's costing her. Performing drains it; being real can restore it.
## The player never sees the numbers. They feel them through:
##   - self-editing: lines with "real_text" are typed, deleted, and replaced
##     by the performed "text" while mask is high. When mask is low she just
##     says the real line.
##   - choice timer: choices marked "timed" give a few seconds, less as mask
##     rises. Running out picks the "perform" choice.
##   - honest choices lock when energy is too low or mask is too high.
##
## Choices use "mask_change" and "energy_change" instead of "weight_change".

@export var starting_mask := 60.0
@export var starting_energy := 60.0

@export_group("Rules")
@export var self_edit_mask := 60.0 ## at or above this, real lines get rewritten
@export var lock_energy_below := 20.0 ## honest choices lock under this energy...
@export var lock_mask_above := 85.0 ## ...or over this mask
@export var timer_max := 8.0 ## seconds on a timed choice at mask 0
@export var timer_min := 4.0 ## seconds on a timed choice at mask 100

const INFO := {
	"meters": {
		"mask": "How much she's performing the version, 0-100. Hidden.",
		"energy": "What performing costs her, 0-100. Hidden.",
	},
	"features": [
		"Self-edit: while mask is high, real lines are typed, deleted, and replaced.",
		"Timed choices: people waiting on her; running out picks the perform answer.",
		"Locked honesty: honest choices lock when energy is low or mask is high.",
	],
	"node_keys": ["real_text", "timed"],
	"choice_keys": ["mask_change", "energy_change"],
	"choice_types": ["neutral", "honest", "helpful", "perform"],
}

var mask := 0.0
var energy := 0.0


func setup(story_player: StoryPlayer) -> void:
	super(story_player)
	mask = starting_mask
	energy = starting_energy


func info() -> Dictionary:
	return INFO


func get_meters() -> Dictionary:
	return {"mask": mask, "energy": energy}

func set_meters(meters: Dictionary) -> void:
	mask = clampf(meters.get("mask", starting_mask), 0.0, 100.0)
	energy = clampf(meters.get("energy", starting_energy), 0.0, 100.0)


func apply_choice(choice: Dictionary) -> void:
	mask = clampf(mask + choice.get("mask_change", 0.0), 0.0, 100.0)
	energy = clampf(energy + choice.get("energy_change", 0.0), 0.0, 100.0)

func is_locked(choice: Dictionary) -> bool:
	return choice.get("type", "") == "honest" and (energy < lock_energy_below or mask > lock_mask_above)


func choice_time(entry: Dictionary) -> float:
	if not entry.get("timed", false):
		return 0.0
	return lerpf(timer_max, timer_min, mask / 100.0)

func timeout_choice(choices: Array) -> Dictionary:
	for c in choices:
		if c.get("type", "") == "perform" and not c.get("locked", false):
			return c
	return super(choices)


func line_for(entry: Dictionary) -> Dictionary:
	if not entry.has("real_text"):
		return {"text": entry.get("text", "")}
	if mask >= self_edit_mask:
		return {"unsaid": entry["real_text"], "text": entry.get("text", "")}
	return {"text": entry["real_text"]}


func describe() -> String:
	return "mask %s | energy %s" % [mask, energy]
