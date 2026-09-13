extends Control

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
		

func _on_character_1_pressed() -> void:
	_show_character(1)
	start.disabled = false

func _on_character_2_pressed() -> void:
	_show_character(2)
	start.disabled = true

func _on_character_3_pressed() -> void:
	_show_character(3)
	start.disabled = true

func _on_character_4_pressed() -> void:
	_show_character(4)
	start.disabled = true

func _on_start_pressed() -> void:
	if charactersel == 0:
		return
	elif charactersel == 1:
		_fade_then(func(): get_tree().change_scene_to_file("res://Scenes/storykay1.tscn"))
	else:
		return
#		_fade_then(func(): get_tree().change_scene_to_file("res://Scenes/Startscreen.tscn"))
