class_name StoryMode
extends Resource
## How one character's story plays: what their meters are, what choices do to
## them, which choices lock, and how the screen and text react.
## StoryPlayer does everything else (dialog, choices, log, saving), so a new
## character only needs a new mode. Set it in the story scene's Inspector under
## "Mode"; numbers exported by a mode can be tuned there too.

## Keys every story can use, whatever the mode.
const BASE_NODE_KEYS := ["speaker", "text", "emotion", "next", "choices", "secret",
	"background", "show_characters", "hide_characters", "expression", "sfx", "amb", "voice", "call"]
const BASE_CHOICE_KEYS := ["text", "type", "next", "set_flag", "requires"]

var player : StoryPlayer


## What this mode is, for people reading the code and for the story checker.
## Override in each mode. Keys:
##   meters       - {name: what it means}; secrets can use "<name>_above/_below"
##   features     - [short descriptions of what the player experiences]
##   node_keys    - extra JSON keys this mode reads on nodes
##   choice_keys  - extra JSON keys this mode reads on choices
##   choice_types - the "type" values this mode understands
func info() -> Dictionary:
	return {"meters": {}, "features": [], "node_keys": [], "choice_keys": [], "choice_types": []}


func setup(story_player: StoryPlayer) -> void:
	player = story_player


## The character's meters by name, e.g. {"weight": 55}. Secrets in the flow
## graph can test any of them with "<name>_above" / "<name>_below".
func get_meters() -> Dictionary:
	return {}

func set_meters(_meters: Dictionary) -> void:
	pass


## Called when the player picks a choice, before moving to its node.
func apply_choice(_choice: Dictionary) -> void:
	pass

## Locked choices are greyed out and can't be picked.
func is_locked(_choice: Dictionary) -> bool:
	return false


## Seconds the player gets to pick, or 0 for no timer.
func choice_time(_entry: Dictionary) -> float:
	return 0.0

## The choice made for the player when the timer runs out.
func timeout_choice(choices: Array) -> Dictionary:
	for c in choices:
		if not c.get("locked", false):
			return c
	return choices[0]


## What gets typed for this node: {"text": ...}, plus "unsaid" for a line
## that's typed, deleted, and replaced by "text". Add "cut": true to have
## "unsaid" broken off and replaced at once instead of deleted.
func line_for(entry: Dictionary) -> Dictionary:
	return {"text": entry.get("text", "")}


## false = clicking can't skip this line's typing; it plays out in full.
func can_skip(_entry: Dictionary) -> bool:
	return true

## false = Auto waits for the player on this line.
func auto_allowed(_entry: Dictionary) -> bool:
	return true

## Typing speed for this one line (on top of speed_multiplier and emotions).
func line_speed(_entry: Dictionary) -> float:
	return 1.0


## Extra warnings about this mode's keys in a story, shown when the game
## starts in the editor.
func validate(_graph: FlowGraph) -> Array[String]:
	return []


## Multiplies typing speed (emotion multipliers are applied on top).
func speed_multiplier() -> float:
	return 1.0

## Update screen tint, sounds, etc. to match the meters.
func apply_effects(_instant := false) -> void:
	pass


## One line for the debug log.
func describe() -> String:
	return str(get_meters())
