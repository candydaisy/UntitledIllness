extends Control

@onready var main: Control = $Main
@onready var selections: Control = $Selections
@onready var credits: Control = $Credits
@onready var gallery: Control = $Gallery
@onready var settings: Control = $Settings
@onready var blink: Control = $Blink

var _all_panels: Array[Control]

func _ready() -> void:
	_all_panels = [main, selections, credits, gallery, settings]
	_show_panel(main)
	blink.modulate.a = 1.0

func _navigate_to(panel: Control) -> void:
	blink.blink()
	_hide_all()
	await blink.tween.finished
	panel.visible = true

func _show_panel(panel: Control) -> void:
	for p in _all_panels:
		p.visible = (p == panel)

func _hide_all() -> void:
	for p in _all_panels:
		p.visible = false

func _on_play_pressed() -> void:
	_navigate_to(selections)

func _on_credits_pressed() -> void:
	_navigate_to(credits)

func _on_gallery_pressed() -> void:
	_navigate_to(gallery)

func _on_settings_pressed() -> void:
	_navigate_to(settings)

func _on_back_pressed() -> void:
	_navigate_to(main)
