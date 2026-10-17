extends Control

## Story scene for each character button, in order (Character1 = first).
## "" = not playable yet; its Start button stays disabled.
const STORY_SCENES := [
	"res://Scenes/Characters/Kay.tscn",  # K. Kay
	"res://Scenes/Characters/Elysia.tscn", # E. Elysia
	"res://Scenes/Characters/Ulyn.tscn",   # U. Ulyn
	"",                                    # R.
]

## What screen readers call each character button (the buttons only show initials).
const NAMES := ["Kay", "Elysia", "Ulyn", "R"]

var charactersel: int = 0

@onready var chars: Array[Control] = [
	$Panel/View/Char1,
	$Panel/View/Char2,
	$Panel/View/Char3,
	$Panel/View/Char4,
]
@onready var start: Button = $Panel/Selectors/Start
@onready var fade: ColorRect = $Panel/Fade

func _ready() -> void:
	_show_character(0)
	fade.modulate.a = 0.0
	fade.visible = false

	# Screen readers: the buttons show only initials, so give them names, and
	# read out the character's description from their card.
	for i in chars.size():
		var button : Button = $Panel/Selectors.get_node("Character%d" % (i + 1))
		button.accessibility_name = NAMES[i] + ("" if STORY_SCENES[i] != "" else ", not playable yet")
		var about := []
		for label in chars[i].find_children("*", "Label", true, false):
			if label.text.strip_edges() != "" and label.name != "Name":
				about.append(label.text.strip_edges())
		button.accessibility_description = " ".join(about)
	start.accessibility_description = tr("Choose a character first.")

func _fade_then(callback: Callable) -> void:
	fade.visible = true
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.5)
	tween.tween_interval(1)
	await tween.finished
	callback.call()

func _show_character(index: int) -> void:
	charactersel = index
	for i in chars.size():
		chars[i].visible = (i + 1 == index)
		

func _select(index: int) -> void:
	_show_character(index)
	start.disabled = STORY_SCENES[index - 1] == ""
	start.accessibility_description = tr("Not playable yet.") if start.disabled else tr("Start %s's story.") % NAMES[index - 1]

func _on_character_1_pressed() -> void:
	_select(1)

func _on_character_2_pressed() -> void:
	_select(2)

func _on_character_3_pressed() -> void:
	_select(3)

func _on_character_4_pressed() -> void:
	_select(4)

func _on_start_pressed() -> void:
	if charactersel == 0 or STORY_SCENES[charactersel - 1] == "":
		return
	var scene : String = STORY_SCENES[charactersel - 1]
	_fade_then(func(): get_tree().change_scene_to_file(scene))
