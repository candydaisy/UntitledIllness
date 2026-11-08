extends SceneTree
## Voice files are found by path, one folder per route (made by the TTFUI
## voice tool); Thai plays the English file. A node's "voice" key overrides the name.
## Run: godot --headless --path . -s res://Tests/test_voice.gd

const CASES := [
	[{}, "Kay", "12", "res://Assets/audio/voice/Kay/12.mp3"],
	[{"voice": "kay_wake_3"}, "Kay", "12", "res://Assets/audio/voice/kay_wake_3.mp3"],
]

func _initialize() -> void:
	for c in CASES:
		for locale in ["en", "th_TH"]: # Thai plays the English voice too
			TranslationServer.set_locale(locale)
			var got := StoryAudio.voice_path(c[0], c[1], c[2])
			if got != c[3]:
				return fail("%s %s/%s %s: got %s, want %s" % [c[0], c[1], c[2], locale, got, c[3]])
	print("PASS")
	quit(0)


func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
