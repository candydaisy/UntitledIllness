extends SceneTree
## The speaker stands out: the others on stage dim, the speaker hops once when
## they start talking, and narration leaves everyone lit.
## Run: godot --headless --path . -s res://Tests/test_speaker_highlight.gd

var chars := Node.new()
var stage : StoryStage

func _initialize() -> void:
	root.add_child(chars)
	for n in ["Kay", "MsNoi", "mom", "ElysiaMom", "Ulyn"]:
		var s := AnimatedSprite2D.new()
		s.name = n
		s.position = Vector2(100, 600)
		s.visible = n != "Ulyn" # Ulyn is off stage
		chars.add_child(s)
	stage = StoryStage.new(root, Node.new(), chars)
	_run()


func _run() -> void:
	if stage.speaker_node("Ms. Noi") != chars.get_node("MsNoi"): return fail("Ms. Noi -> MsNoi")
	if stage.speaker_node("Ulyn's mom") != chars.get_node("mom"): return fail("Ulyn's mom -> mom")
	if stage.speaker_node("Elysia's mom") != chars.get_node("ElysiaMom"): return fail("Elysia's mom -> ElysiaMom")
	if stage.speaker_node("???") != null or stage.speaker_node("") != null: return fail("??? / narration map to nobody")

	stage.highlight("Kay")
	await create_timer(0.07).timeout
	if chars.get_node("Kay").position.y >= 600: return fail("Kay didn't hop")
	await create_timer(0.6).timeout
	if chars.get_node("Kay").position.y != 600: return fail("Kay didn't land back")
	if chars.get_node("Kay").self_modulate != Color.WHITE: return fail("speaker dimmed")
	if chars.get_node("MsNoi").self_modulate.r > 0.6: return fail("listener not dimmed")

	stage.highlight("Kay") # same speaker again: no second hop
	await create_timer(0.07).timeout
	if chars.get_node("Kay").position.y != 600: return fail("hopped again on the same speaker")

	stage.highlight("Ulyn") # talking off stage: nobody dims
	await create_timer(0.6).timeout
	for n in ["Kay", "MsNoi", "mom", "ElysiaMom"]:
		if chars.get_node(n).self_modulate != Color.WHITE: return fail(n + " still dim with an off-stage speaker")
	print("PASS")
	quit(0)


func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
