extends SceneTree
## The overwater, the_version and type_delete minigames end with the result
## the story expects for each way of playing them.
## Run: godot --headless --path . -s res://Tests/test_new_minigames.gd

var _result := ""


func _initialize() -> void:
	_run.call_deferred() # the root isn't ready to take children during _initialize


func _run() -> void:
	# Overwater: leave it, stop at the line, pour too long.
	var g := _make("overwater", {}, {"weight": 0})
	g._finish(g._judge())
	if not _expect("left_it"): return
	g = _make("overwater", {}, {"weight": 0})
	g._poured = true
	g._holding = true
	while g.soil.value < g._line and _result == "":
		g._process(0.01)
	g.release()
	if not _expect("right"): return
	g = _make("overwater", {}, {"weight": 100})
	g._poured = true
	g._holding = true
	for i in 1000:
		g._process(0.01)
	if not _expect("drowned"): return

	# The Version: matched sliders are perfect, a tired face is real.
	g = _make("the_version", {}, {"mask": 0})
	g._finish(g.result())
	if not _expect("real"): return
	g = _make("the_version", {}, {"mask": 0})
	g.smile.value = g._target.x
	g.eyes.value = g._target.y
	g.take.pressed.emit()
	if not _expect("perfect"): return

	# Type & delete: send with text, or let it delete itself.
	g = _make("type_delete", {}, {"unsaid": 0})
	for i in 5:
		g.type_letter()
	g.press_send()
	if not _expect("sent"): return
	g = _make("type_delete", {}, {"unsaid": 100})
	g.type_letter()
	for i in 100:
		g._process(0.05)
	if not _expect("deleted"): return
	g = _make("type_delete", {}, {"unsaid": 0})
	g.press_send() # nothing typed: Send does nothing
	if _result != "":
		return fail("type_delete sent an empty message")

	print("PASS")
	quit(0)


func _make(scene_name: String, settings: Dictionary, meters: Dictionary) -> Control:
	_result = ""
	var g = load("res://Scenes/Minigames/%s.tscn" % scene_name).instantiate()
	g.start(settings, meters)
	root.add_child(g)
	g.finished.connect(func(r): _result = r)
	return g


func _expect(want: String) -> bool:
	if _result != want:
		fail("expected '%s', got '%s'" % [want, _result])
		return false
	return true


func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
