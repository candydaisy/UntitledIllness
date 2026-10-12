class_name UlynMode
extends StoryMode
## Ulyn: two hidden meters.
##   busy   - how full he keeps his life so he never has to sit still.
##            Taking things on raises it; dropping them lowers it.
##   unsaid - everything he hasn't told anyone. It piles up while he avoids
##            things and only goes down when he's honest. Decides the ending.
## The player feels them through:
##   - cut-off thoughts: while busy is high, a line with "cut" is typed up to
##     "cut_after", breaks off with a dash, and jumps to the "cut" line.
##   - quiet scenes: lines with "quiet": true type slowly and can't be skipped
##     or auto-advanced. While he's busy, every other line types faster.
##   - phone calls: a node with "call" rings for a few seconds; letting it
##     ring out picks the "neutral" choice (decline).
##   - "open" choices (honest about himself) lock while busy is high.
##     Honest about others and helpful choices never lock: he can always help
##     someone else.
##
## Choices use "busy_change" and "unsaid_change" instead of "weight_change".

const INFO := {
	"meters": {
		"busy": "How full he keeps his life, 0-100. Hidden.",
		"unsaid": "What he hasn't told anyone, 0-100. Hidden. Decides the ending.",
	},
	"features": [
		"Cut-off thoughts: while busy is high, thoughts about home break off into a task.",
		"Quiet scenes: slow, can't be skipped or auto-advanced. Busy scenes rush.",
		"Phone calls: ring for a few seconds; letting them ring out declines.",
		"Locked openness: 'open' choices (honest about himself) lock when busy is high.",
	],
	"node_keys": ["quiet", "cut", "cut_after"],
	"choice_keys": ["busy_change", "unsaid_change"],
	"choice_types": ["neutral", "honest", "helpful", "open"],
}

@export var starting_busy := 60.0
@export var starting_unsaid := 50.0

@export_group("Rules")
@export var lock_busy_above := 80.0 ## "open" choices lock over this busy
@export var cut_busy := 60.0 ## at or above this busy, thoughts with "cut" break off
@export var call_ring_time := 6.0 ## seconds a call rings before it's declined
@export var quiet_speed := 0.6 ## typing speed on quiet lines
@export var rush_per_busy := 0.01 ## other lines type this much faster per busy point over 50

var busy := 0.0
var unsaid := 0.0


func setup(story_player: StoryPlayer) -> void:
	super(story_player)
	busy = starting_busy
	unsaid = starting_unsaid


func info() -> Dictionary:
	return INFO


func get_meters() -> Dictionary:
	return {"busy": busy, "unsaid": unsaid}

func set_meters(meters: Dictionary) -> void:
	busy = clampf(meters.get("busy", starting_busy), 0.0, 100.0)
	unsaid = clampf(meters.get("unsaid", starting_unsaid), 0.0, 100.0)


func apply_choice(choice: Dictionary) -> void:
	busy = clampf(busy + choice.get("busy_change", 0.0), 0.0, 100.0)
	unsaid = clampf(unsaid + choice.get("unsaid_change", 0.0), 0.0, 100.0)

func is_locked(choice: Dictionary) -> bool:
	return choice.get("type", "") == "open" and busy > lock_busy_above


func choice_time(entry: Dictionary) -> float:
	return call_ring_time if entry.has("call") else 0.0

## A call that rings out is declined: the "neutral" choice.
func timeout_choice(choices: Array) -> Dictionary:
	for c in choices:
		if c.get("type", "") == "neutral" and not c.get("locked", false):
			return c
	return super(choices)


func line_for(entry: Dictionary) -> Dictionary:
	var text : String = entry.get("text", "")
	if entry.has("cut") and busy >= cut_busy:
		var after : String = entry.get("cut_after", "")
		var at := text.find(after)
		if after != "" and at >= 0:
			return {"unsaid": text.substr(0, at + after.length()).strip_edges() + "—", "text": entry["cut"], "cut": true}
	return {"text": text}


func can_skip(entry: Dictionary) -> bool:
	return not entry.get("quiet", false)

func auto_allowed(entry: Dictionary) -> bool:
	return not entry.get("quiet", false)

func line_speed(entry: Dictionary) -> float:
	if entry.get("quiet", false):
		return quiet_speed
	return 1.0 + maxf(busy - 50.0, 0.0) * rush_per_busy


func validate(graph: FlowGraph) -> Array[String]:
	var problems : Array[String] = []
	for id in graph.nodes:
		var entry : Dictionary = graph.nodes[id]
		if entry.has("cut") and String(entry.get("text", "")).find(entry.get("cut_after", "")) < 0:
			problems.append("Node %s: cut_after '%s' isn't in its text" % [id, entry.get("cut_after", "")])
		if entry.has("cut_after") and not entry.has("cut"):
			problems.append("Node %s: has cut_after but no cut" % id)
	return problems


func describe() -> String:
	return "busy %s | unsaid %s" % [busy, unsaid]
