class_name SettingMenu
extends Control
## The pause / settings menu. The same scene is used on the title screen and
## inside the story (Dialog/Setting). Volumes are saved to user://settings.cfg,
## so both copies always show the same values.

signal closed # Return was pressed (the title screen uses this to show itself again)

const SETTINGS_PATH := "user://settings.cfg"
const TITLE_SCENE := "res://Scenes/Menus/title_menu.tscn"
const EMPTY_SLOT_TINT := Color(1, 1, 1, 0.35)

@onready var setting_panel : Panel = $"Sub1-setting"
@onready var save_panel : Panel = $"Sub2-save"
@onready var load_panel : Panel = $"Sub3-load"
@onready var confirm : Panel = $Confirm
@onready var confirm_label : Label = $Confirm/Label

## Slider -> bus name. Bus names must match the Audio tab at the bottom of the editor.
@onready var sliders := {
	$"Sub1-setting/Master-slider": "Master",
	$"Sub1-setting/Amb-slider": "Ambience",
	$"Sub1-setting/Sfx-slider": "Sfx",
	$"Sub1-setting/Voice-slider": "Voice",
}

@onready var save_slots : Array = $"Sub2-save/Container".get_children()
@onready var load_slots : Array = $"Sub3-load/Container".get_children()

var screenshot : Image # taken when the menu opens in-game, before it covers the screen
var _pending_action : Callable # what Confirm does


func _ready() -> void:
	apply_saved_volumes()

	for slider in sliders:
		var bus := AudioServer.get_bus_index(sliders[slider])
		if bus == -1:
			push_warning("Setting menu: no audio bus named '%s'" % sliders[slider])
			slider.editable = false
			continue
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = AudioServer.get_bus_volume_linear(bus)
		slider.value_changed.connect(_on_volume_changed.bind(bus))
		slider.drag_ended.connect(func(_changed): _save_volumes())

	$Main/Setting.pressed.connect(_show_sub.bind(setting_panel))
	$Main/Save.pressed.connect(_show_sub.bind(save_panel))
	$Main/Load.pressed.connect(_show_sub.bind(load_panel))
	$Main/Return.pressed.connect(close)
	$Main/Exit.pressed.connect(_on_exit_pressed)
	$Confirm/Button.pressed.connect(_on_confirm)
	$Confirm/Button2.pressed.connect(_hide_confirm)

	for i in save_slots.size():
		save_slots[i].pressed.connect(_on_save_slot.bind(i + 1))
	for i in load_slots.size():
		load_slots[i].pressed.connect(_on_load_slot.bind(i + 1))
		_add_slot_label(load_slots[i])
	for slot in save_slots:
		_add_slot_label(slot)


## Shows the menu on the Settings page. In-game, call this before anything
## covers the screen so the save thumbnail is a picture of the story.
func open() -> void:
	screenshot = get_viewport().get_texture().get_image() if _story() else null
	$Main/Save.disabled = _story() == null # nothing to save on the title screen
	_hide_confirm()
	_show_sub(setting_panel)
	visible = true

func close() -> void:
	_hide_confirm()
	visible = false
	closed.emit()


func _story() -> StoryPlayer:
	return get_tree().current_scene as StoryPlayer

func _show_sub(panel: Panel) -> void:
	for p in [setting_panel, save_panel, load_panel]:
		p.visible = (p == panel)
	if panel != setting_panel:
		_refresh_slots()



# --- Volume ---

func _on_volume_changed(value: float, bus: int) -> void:
	AudioServer.set_bus_volume_linear(bus, value)
	AudioServer.set_bus_mute(bus, value <= 0.0)

func _save_volumes() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # keep other sections if there are any
	for slider in sliders:
		cfg.set_value("volume", sliders[slider], slider.value)
	cfg.save(SETTINGS_PATH)

static func apply_saved_volumes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK or not cfg.has_section("volume"):
		return
	for bus_name in cfg.get_section_keys("volume"):
		var bus := AudioServer.get_bus_index(bus_name)
		if bus != -1:
			var value : float = cfg.get_value("volume", bus_name)
			AudioServer.set_bus_volume_linear(bus, value)
			AudioServer.set_bus_mute(bus, value <= 0.0)



# --- Save / load ---

func _on_save_slot(slot: int) -> void:
	if SaveGame.exists(slot):
		_ask("Overwrite slot %d?" % slot, _save_to.bind(slot))
	else:
		_save_to(slot)

func _save_to(slot: int) -> void:
	SaveGame.write(slot, _story().get_save_data(), screenshot)
	_refresh_slots()

func _on_load_slot(slot: int) -> void:
	if not SaveGame.exists(slot):
		return
	if _story():
		_ask("Load slot %d?\nUnsaved progress is lost." % slot, SaveGame.load_slot.bind(get_tree(), slot))
	else:
		SaveGame.load_slot(get_tree(), slot)

func _refresh_slots() -> void:
	for slots in [save_slots, load_slots]:
		for i in slots.size():
			var button : TextureButton = slots[i]
			var slot : int = i + 1
			var label : Label = button.get_node("SlotLabel")
			if not button.has_meta("empty_texture"):
				button.set_meta("empty_texture", button.texture_normal)
			if SaveGame.exists(slot):
				var data := SaveGame.read(slot)
				var thumb := SaveGame.thumbnail(slot)
				button.texture_normal = thumb if thumb else button.get_meta("empty_texture")
				button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED if thumb else TextureButton.STRETCH_TILE
				button.modulate = Color.WHITE
				label.text = "%d  %s\n%s" % [slot, data.get("character", ""), String(data.get("saved_at", "")).replace("T", "  ")]
			else:
				button.texture_normal = button.get_meta("empty_texture")
				button.stretch_mode = TextureButton.STRETCH_TILE
				button.modulate = EMPTY_SLOT_TINT if slots == load_slots else Color.WHITE
				label.text = "%d  Empty" % slot

func _add_slot_label(button: TextureButton) -> void:
	var label := Label.new()
	label.name = "SlotLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -64
	label.offset_left = 12
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)



# --- Exit / confirm ---

func _on_exit_pressed() -> void:
	if _story():
		_ask("Back to the title screen?\nUnsaved progress is lost.", get_tree().change_scene_to_file.bind(TITLE_SCENE))
	else:
		_ask("Quit the game?", get_tree().quit)

func _ask(question: String, action: Callable) -> void:
	confirm_label.text = question
	_pending_action = action
	confirm.visible = true

func _on_confirm() -> void:
	var action := _pending_action
	_hide_confirm()
	if action.is_valid():
		action.call()

func _hide_confirm() -> void:
	confirm.visible = false
	confirm_label.text = "Are you sure?"
	_pending_action = Callable()
