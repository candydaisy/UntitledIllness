class_name FlowGraph
extends RefCounted
## A character's story, loaded from a flow_graph.json file.

var nodes : Dictionary = {}


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
	graph.nodes = json.data
	return graph


func has_entry(id: String) -> bool:
	return nodes.has(id)

func get_entry(id: String) -> Dictionary:
	return nodes.get(id, {})


## Returns the node a "secret" redirects to, or "" when its condition isn't met.
func secret_target(entry: Dictionary, weight: float, flags: Dictionary) -> String:
	if not entry.has("secret"):
		return ""

	var secret : Dictionary = entry["secret"]
	var met : bool
	match secret.get("condition", ""):
		"weight_above": met = weight > secret.get("value", 0)
		"weight_below": met = weight < secret.get("value", 0)
		"flag_true":    met = flags.get(secret.get("flag", ""), false)
		"flag_false":   met = not flags.get(secret.get("flag", ""), false)
		_:              met = false

	return secret.get("next", "") if met else ""


## Lists every "next" that points to a node that doesn't exist.
func find_broken_links() -> Array[String]:
	var problems : Array[String] = []
	for id in nodes:
		var entry : Dictionary = nodes[id]
		var targets := [entry.get("next", "")]
		for choice in entry.get("choices", []):
			targets.append(choice.get("next", ""))
		if entry.has("secret"):
			targets.append(entry["secret"].get("next", ""))
		for target in targets:
			if target != "" and not nodes.has(target):
				problems.append("Node %s points to missing node %s" % [id, target])
	return problems
