extends SceneTree
## Thai story files: th.json next to flow_graph.json is merged over the
## English by node id; anything missing stays English; story logic is untouched.
## Run: godot --headless --path . -s res://Tests/test_story_language.gd

const DIR := "user://test_story_language"
const ENGLISH := {
	"a": {"speaker": "Kay", "text": "Hello.", "next": "b"},
	"b": {"text": "Pick one.", "choices": [
		{"text": "Left", "next": "a", "weight_change": 5},
		{"text": "Secret", "next": "a", "requires": "Noticed"},
		{"text": "Right", "next": "a", "set_flag": "WentRight"}]},
	"c": {"text": "*Beep.*", "minigame": "res://x.tscn", "results": {
		"won": {"text": "Got up", "next": "a"}, "gave_up": {"text": "Stayed", "next": "a"}}},
	"d": {"text": "Not translated yet.", "next": "a"},
}
const THAI := {
	"a": {"text": "สวัสดี"},
	"b": {"text": "เลือกสักอัน", "choices": ["ซ้าย", "ความลับ", "ขวา"]},
	"c": {"text": "*ปี๊บ*", "results": {"won": "ลุกแล้ว", "gave_up": "นอนต่อ"}},
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_write("flow_graph.json", JSON.stringify(ENGLISH))
	_write("th.json", JSON.stringify(THAI))

	TranslationServer.set_locale("th")
	var g := FlowGraph.load_from(DIR + "/flow_graph.json")
	if g.nodes["a"]["text"] != "สวัสดี": return fail("text not translated: " + g.nodes["a"]["text"])
	if g.nodes["a"]["speaker"] != "Kay": return fail("speaker changed")
	var ch : Array = g.nodes["b"]["choices"]
	if [ch[0]["text"], ch[1]["text"], ch[2]["text"]] != ["ซ้าย", "ความลับ", "ขวา"]: return fail("choices wrong: %s" % [ch])
	if ch[1]["requires"] != "Noticed" or ch[2]["set_flag"] != "WentRight" or ch[0]["weight_change"] != 5:
		return fail("choice logic changed")
	if g.nodes["c"]["results"]["won"]["text"] != "ลุกแล้ว" or g.nodes["c"]["results"]["won"]["next"] != "a":
		return fail("results wrong")
	if g.nodes["d"]["text"] != "Not translated yet.": return fail("missing node didn't fall back to English")
	if g.source["a"]["text"] != "Hello.": return fail("source (English) was changed")
	if g.translated_count() != Vector2i(3, 4): return fail("translated_count %s" % g.translated_count())

	g.apply_language("en")
	if g.nodes["a"]["text"] != "Hello." or g.nodes["b"]["choices"][0]["text"] != "Left":
		return fail("English didn't come back")

	_write("th.json", "{ this is not json")
	g.apply_language("th")
	if g.nodes["a"]["text"] != "Hello.": return fail("broken th.json should leave English")

	TranslationServer.set_locale("en")
	print("PASS")
	quit(0)

func _write(file: String, text: String) -> void:
	var f := FileAccess.open(DIR.path_join(file), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func fail(reason: String) -> void:
	TranslationServer.set_locale("en")
	print("FAIL: ", reason)
	quit(1)
