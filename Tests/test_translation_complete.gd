extends SceneTree
## A route's th.json is complete and passes the checker: every line, choice,
## result, self-edit and cut-off has Thai.
## Run: godot --headless --path . -s res://Tests/test_translation_complete.gd -- Kay
## (With no route given it checks all three, so run_all.sh covers them.)

const KEYS := ["text", "real_text", "cut", "cut_after"]

func _initialize() -> void:
	var routes := OS.get_cmdline_user_args()
	if routes.is_empty():
		routes = ["Kay", "Elysia", "Ulyn"]
	var failed := false
	for route in routes:
		var g := FlowGraph.load_from("res://Story/%s/flow_graph.json" % route)
		g.apply_language("th")
		var missing := []
		for id in g.source:
			var en : Dictionary = g.source[id]
			var th : Dictionary = g.translation.get(id, {})
			for key in KEYS:
				if en.has(key) and not th.has(key):
					missing.append("%s.%s" % [id, key])
			if en.has("choices") and th.get("choices", []).size() != en["choices"].size():
				missing.append("%s.choices" % id)
			for name in en.get("results", {}):
				if not th.get("results", {}).has(name):
					missing.append("%s.results.%s" % [id, name])
		var problems := g.check_translation(g.translation)
		var count := g.translated_count()
		print("%s: %d/%d lines, %d missing, %d problems" % [route, count.x, count.y, missing.size(), problems.size()])
		for p in problems.slice(0, 10):
			print("  problem: ", p)
		if not missing.is_empty():
			print("  first missing: ", missing.slice(0, 5))
		failed = failed or not missing.is_empty() or not problems.is_empty()
	if failed:
		print("FAIL: translation incomplete")
		quit(1)
	else:
		print("PASS")
		quit(0)
