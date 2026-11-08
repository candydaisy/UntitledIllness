extends SceneTree
## ElevenLabs audio tags in the story JSON ([sighs], [softly, to himself]) are
## for the voice tool only; the game strips them when it loads the lines.
## Run: godot --headless --path . -s res://Tests/test_voice_tags.gd

const CASES := [
	["[tired] [sighs] Monday...", "Monday..."],
	["[nervous] \"Y-you're one to talk.\"", "\"Y-you're one to talk.\""],
	["\"[awkward laugh] Ha... [modest] it's nothing.\"", "\"Ha... it's nothing.\""],
	["[softly, to himself] {the basil|Basil} again", "{the basil|Basil} again"],
	["*No tags here.*", "*No tags here.*"],
	["  untouched  ", "  untouched  "],
]

func _initialize() -> void:
	for c in CASES:
		var lines := {"a": {"text": c[0], "real_text": c[0]}}
		FlowGraph.strip_voice_tags(lines)
		for key in ["text", "real_text"]:
			if lines["a"][key] != c[1]:
				return fail("%s: got %s, want %s" % [c[0], lines["a"][key], c[1]])
	print("PASS")
	quit(0)


func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
