class_name FlowGraph
extends RefCounted
## A character's story, loaded from a flow_graph.json file.
## A translation sits next to it as <locale>.json (e.g. th.json), keyed by
## node id; see apply_language().

const TRANSLATABLE := ["text", "real_text", "cut", "cut_after"]

var nodes : Dictionary = {} # what the game reads: English with the translation on top
var source : Dictionary = {} # the English, never changed
var translation : Dictionary = {} # the loaded <locale>.json, {} for English
var _path := ""


static func load_from(path: String) -> FlowGraph:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Flow graph not found at: " + path)
		return null
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Failed to parse %s (line %d): %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Flow graph must be a JSON object: " + path)
		return null

	var graph := FlowGraph.new()
	graph.source = json.data
	graph._path = path
	graph.apply_language(TranslationServer.get_locale())
	return graph


## Rebuilds `nodes` for a locale: the English, with every line the
## translation has replaced. Anything it's missing stays English, and only
## text changes, never next/flags/meters.
func apply_language(locale: String) -> void:
	nodes = source.duplicate(true)
	translation = _load_translation(locale)
	for id in translation:
		if not nodes.has(id) or typeof(translation[id]) != TYPE_DICTIONARY:
			continue
		var entry : Dictionary = nodes[id]
		var tr_entry : Dictionary = translation[id]
		for key in TRANSLATABLE:
			if tr_entry.has(key) and entry.has(key):
				entry[key] = tr_entry[key]
		var choices : Array = entry.get("choices", [])
		var tr_choices : Array = tr_entry.get("choices", [])
		for i in mini(choices.size(), tr_choices.size()): # by index, before any filtering
			choices[i]["text"] = tr_choices[i]
		var results : Dictionary = entry.get("results", {})
		var tr_results : Dictionary = tr_entry.get("results", {})
		for name in tr_results:
			if results.has(name):
				results[name]["text"] = tr_results[name]

func _load_translation(locale: String) -> Dictionary:
	var file := _path.get_base_dir().path_join(locale.get_slice("_", 0) + ".json")
	if locale.begins_with("en") or _path == "" or not FileAccess.file_exists(file):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("Can't read %s (line %d): %s. Playing in English." % [file, json.get_error_line(), json.get_error_message()])
		return {}
	return json.data

## (translated nodes, nodes with text), for the progress line in the editor.
func translated_count() -> Vector2i:
	var total := 0
	var done := 0
	for id in source:
		if source[id].has("text"):
			total += 1
			if translation.get(id, {}).has("text"):
				done += 1
	return Vector2i(done, total)


func has_entry(id: String) -> bool:
	return nodes.has(id)

func get_entry(id: String) -> Dictionary:
	return nodes.get(id, {})


## Returns the node a "secret" redirects to, or "" when its condition isn't met.
## Meter conditions are "<meter>_above" / "<meter>_below", for whatever meters
## the character's mode has (Kay: weight; Elysia: mask, energy).
func secret_target(entry: Dictionary, meters: Dictionary, flags: Dictionary) -> String:
	if not entry.has("secret"):
		return ""

	var secret : Dictionary = entry["secret"]
	var condition : String = secret.get("condition", "")
	var met := false
	match condition:
		"flag_true":  met = flags.get(secret.get("flag", ""), false)
		"flag_false": met = not flags.get(secret.get("flag", ""), false)
		_:
			var meter := condition.trim_suffix("_above").trim_suffix("_below")
			if not meters.has(meter):
				push_warning("Secret uses unknown condition '%s'" % condition)
			elif condition.ends_with("_above"):
				met = meters[meter] > secret.get("value", 0)
			else:
				met = meters[meter] < secret.get("value", 0)

	return secret.get("next", "") if met else ""


## Lists every "next" that points to a node that doesn't exist.
func find_broken_links() -> Array[String]:
	var problems : Array[String] = []
	for id in nodes:
		var entry : Dictionary = nodes[id]
		var targets := [entry.get("next", "")]
		for choice in entry.get("choices", []) + entry.get("results", {}).values():
			targets.append(choice.get("next", ""))
		if entry.has("secret"):
			targets.append(entry["secret"].get("next", ""))
		for target in targets:
			if target != "" and not nodes.has(target):
				problems.append("Node %s points to missing node %s" % [id, target])
	return problems


## Every flag the story sets or checks, sorted (for the debug menu).
func flag_names() -> Array:
	var notice := RegEx.create_from_string(Accessibility.NOTICE)
	var found := {}
	for id in nodes:
		var entry : Dictionary = nodes[id]
		for choice in entry.get("choices", []) + entry.get("results", {}).values():
			for key in ["set_flag", "requires"]:
				if choice.has(key):
					found[choice[key]] = true
		if entry.get("secret", {}).has("flag"):
			found[entry["secret"]["flag"]] = true
		for m in notice.search_all(String(entry.get("text", ""))):
			found[m.get_string(2)] = true
	var names := found.keys()
	names.sort()
	return names
