extends SceneTree
## Voice files are found by path, one folder per route, with _th for Thai
## (made by the TTFUI voice tool). A node's "voice" key overrides the name.
## Run: godot --headless --path . -s res://Tests/test_voice.gd

const CASES := [
	[{}, "Kay", "12", "en", "res://Assets/audio/voice/Kay/12.mp3"],
	[{}, "Kay", "12", "th_TH", "res://Assets/audio/voice/Kay/12_th.mp3"],
	[{"voice": "kay_wake_3"}, "Kay", "12", "en_US", "res://Assets/audio/voice/kay_wake_3.mp3"],
	[{"voice": "kay_wake_3"}, "Kay", "12", "th", "res://Assets/audio/voice/kay_wake_3_th.mp3"],
]

func _initialize() -> void:
	for c in CASES:
		var got := StoryAudio.voice_path(c[0], c[1], c[2], c[3])
		if got != c[4]:
			return fail("%s %s/%s %s: got %s, want %s" % [c[0], c[1], c[2], c[3], got, c[4]])
	print("PASS")
	quit(0)


func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
