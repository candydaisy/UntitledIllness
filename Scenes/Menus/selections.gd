extends Control

## Story scene for each character button, in order (Character1 = first).
## "" = not playable yet; its Start button stays disabled.
const STORY_SCENES := [
	"res://Scenes/Characters/Story.tscn",  # K. Kay
	"res://Scenes/Characters/Elysia.tscn", # E. Elysia
	"",                                    # U. Ulyn
	"",                                    # R.
]

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
	print(get_children())

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
