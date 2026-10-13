extends Control

@onready var main: Control = $Main
@onready var selections: Control = $Selections
@onready var credits: Control = $Credits
@onready var gallery: Control = $Gallery
@onready var settings: Control = $Settings
@onready var blink: Control = $Blink
@onready var setting_menu: SettingMenu = $Settings/Setting

var _all_panels: Array[Control]

func _ready() -> void:
	_all_panels = [main, selections, credits, gallery, settings]
	_show_panel(main)
	blink.modulate.a = 1.0
	setting_menu.closed.connect(_on_back_pressed) # Return brings the title menu back
	$Main/Settings.accessibility_name = "Settings"
	$Main/Settings.accessibility_description = "Volume, save and load."
	_focus(main)

func _navigate_to(panel: Control) -> void:
	blink.blink()
	_hide_all()
	await blink.tween.finished
	panel.visible = true
	_focus(panel)

## Puts keyboard / screen reader focus somewhere useful on the panel that just opened.
func _focus(panel: Control) -> void:
	if panel == settings:
		return # the setting menu focuses itself when it opens
	var web := panel.get_node_or_null("RelationshipWeb") as Control
	if web:
		Accessibility.focus(web)
	else:
		Accessibility.focus_first_button.call_deferred(panel)

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
	await _navigate_to(settings)
	setting_menu.open()

func _on_back_pressed() -> void:
	_navigate_to(main)
