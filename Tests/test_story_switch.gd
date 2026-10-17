extends SceneTree
## Switching language mid-story redraws the current line, choices and phone
## buttons without moving the story; saves load in the current language;
## the checker catches broken Thai lines.
## Run: godot --headless --path . -s res://Tests/test_story_switch.gd

const DIR := "user://test_story_switch"
const ENGLISH := {
	"q": {"speaker": "Kay", "text": "Question?", "choices": [
		{"text": "Yes", "next": "z", "weight_change": 5}, {"text": "No", "next": "z"}]},
	"ring": {"text": "Ring.", "call": "Mom", "choices": [{"text": "Decline", "type": "neutral", "next": "z"}]},
	"z": {"text": "The end of {the hall|SawHall}.", "next": ""},
	"cutme": {"text": "She's at the table right now.", "cut_after": "She's at the table", "cut": "Answer the chat.", "next": "z"},
	"m": {"text": "Beep.", "minigame": "res://x.tscn", "results": {"won": {"text": "Up", "next": "z"}}},
}
const THAI := {
	"q": {"text": "คำถาม?", "choices": ["ใช่", "ไม่"]},
	"ring": {"text": "โทรศัพท์ดัง", "choices": ["ปฏิเสธสาย"]},
	"z": {"text": "สุด{ทางเดิน|SawHall}"},
}

var story
var _saved_locale := "en"

func _initialize() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SettingMenu.SETTINGS_PATH)
	_saved_locale = cfg.get_value("general", "locale", "en") # restored at the end
	DirAccess.make_dir_recursive_absolute(DIR)
	_write("flow_graph.json", JSON.stringify(ENGLISH))
	_write("th.json", JSON.stringify(THAI))
	SettingMenu.set_locale("en")

	# 1. Choices on screen, then switch.
	await _start("q")
	await _until(func(): return story.choices_container.visible)
	var log_size : int = story.dialog_log.get_lines().size()
	var weight : float = story.mode.weight.value
	SettingMenu.set_locale("th")
	await process_frame
	await process_frame
	if story.current_node != "q": return fail("switch moved the story to " + story.current_node)
	var shown = story.choice_buttons.filter(func(b): return b.visible).map(func(b): return b.text)
	shown.sort()
	if shown != ["ใช่", "ไม่"]:
		return fail("choice buttons not Thai: %s" % [story.choice_buttons.map(func(b): return b.text)])
	if story.dialog_log.get_lines().size() != log_size: return fail("log grew on switch")
	if not "คำถาม" in story.dialog_log.get_lines().back(): return fail("last log line not redrawn")
	if not "คำถาม" in story.text_label.text: return fail("dialog line not Thai: " + story.text_label.text)
	if story.mode.weight.value != weight: return fail("meters changed")
	story.free()

	# 2. A phone call on screen, then switch.
	SettingMenu.set_locale("en")
	await _start("ring")
	await _until(func(): return story.phone.visible)
	SettingMenu.set_locale("th")
	await process_frame
	await process_frame
	var phone_texts = story.phone.find_children("*", "Button", true, false).map(func(b): return b.text)
	if phone_texts != ["ปฏิเสธสาย"]: return fail("phone buttons not Thai: %s" % [phone_texts])
	story.free()

	# 3. A save made in English loads in Thai; older log lines stay English.
	SettingMenu.set_locale("th")
	SaveGame.pending = {"node": "z", "meters": {"weight": 40.0}, "flags": {},
		"stage": {"backgrounds": [], "characters": {}}, "log": ["Kay\nQuestion?", "> Yes", "The end of the hall."]}
	await _start("q")
	await process_frame
	if not "ทางเดิน" in story.text_label.text: return fail("loaded line not Thai: " + story.text_label.text)
	if story.dialog_log.get_lines()[0] != "Kay\nQuestion?": return fail("old log line was changed")
	story.free()

	# 4. The checker.
	var bad := {
		"nope": {"text": "x"},                                   # no such node
		"q": {"text": "x", "choices": ["only one"]},             # wrong choice count
		"m": {"text": "x", "results": {"lost": "x"}},            # unknown result
		"z": {"text": "no link here"},                           # lost {…|SawHall}
		"cutme": {"text": "อยู่ที่โต๊ะ", "cut_after": "ไม่ตรง", "cut": "ตอบแชท"},  # cut_after not a prefix
	}
	var g := FlowGraph.new()
	g.source = ENGLISH
	var problems = g.check_translation(bad)
	for word in ["nope", "choice", "lost", "SawHall", "cut_after"]:
		if problems.filter(func(p): return word in p).is_empty():
			return fail("checker missed '%s': %s" % [word, problems])
	if not g.check_translation(THAI).is_empty(): return fail("checker flagged good lines: %s" % [g.check_translation(THAI)])

	SettingMenu.set_locale(_saved_locale)
	print("PASS")
	quit(0)

func _start(node: String) -> void:
	story = load("res://Scenes/Characters/Kay.tscn").instantiate()
	story.flow_graph_path = DIR + "/flow_graph.json"
	story.start_node = node
	root.add_child(story)
	current_scene = story
	await process_frame

func _until(cond: Callable) -> void:
	var t0 := Time.get_ticks_msec()
	while not cond.call() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame

func _write(file: String, text: String) -> void:
	var f := FileAccess.open(DIR.path_join(file), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func fail(reason: String) -> void:
	SettingMenu.set_locale(_saved_locale)
	print("FAIL: ", reason)
	quit(1)
