extends SceneTree
## Thai vowels and tone marks sit above or below their letter. The typewriter
## must never stop between a letter and its marks, while typing or deleting.
## Run: godot --headless --path . -s res://Tests/test_typewriter_thai.gd

const MARKS := "ัิีึืฺุู็่้๊๋์ํ๎"

func _initialize() -> void:
	var label := RichTextLabel.new()
	var sound := AudioStreamPlayer.new()
	root.add_child(label)
	root.add_child(sound)
	var tw := Typewriter.new(label, sound)
	tw.speed = 30.0

	tw.start("น้ำ ที่นี่ ก็ได้")
	for i in 400:
		tw.tick(1.0 / 60.0)
		if _split(label):
			return fail("typing stopped before a mark at %d of '%s'" % [label.visible_characters, label.get_parsed_text()])
		if not tw.is_typing:
			break

	tw.start_edit("ที่นี่ น้ำ", "ไม่")
	var deleted_seen := false
	for i in 1000:
		tw.tick(1.0 / 60.0)
		if tw._phase == Typewriter.Phase.DELETING:
			deleted_seen = true
			if _split(label):
				return fail("deleting stopped before a mark at %d" % label.visible_characters)
		if not tw.is_typing:
			break
	if not deleted_seen:
		return fail("never reached the deleting phase")
	print("PASS")
	quit(0)

## True when the character right after the visible part is a mark, i.e. a
## letter is showing without its vowel or tone mark.
func _split(label: RichTextLabel) -> bool:
	var text := label.get_parsed_text()
	var v := label.visible_characters
	return v > 0 and v < text.length() and text[v] in MARKS

func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
