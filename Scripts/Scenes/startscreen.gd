extends Control

@onready var splash_screen: TextureRect = $CenterContainer/TextureRect

func _ready() -> void:
	if splash_screen == null:
		push_error("Splash screen TextureRect not found")
		return
	
	splash_screen.modulate = Color.TRANSPARENT
	
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(splash_screen, "modulate", Color.WHITE, 1.5)
	tween.tween_interval(1.5)
	tween.tween_property(splash_screen, "modulate", Color.TRANSPARENT, 1.5)
	tween.tween_interval(0.5)
	
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/title_menu.tscn")
