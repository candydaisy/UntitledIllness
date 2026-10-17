class_name SettingMenu
extends Control
## The pause / settings menu. The same scene is used on the title screen and
## inside the story (Dialog/Setting). Volumes are saved to user://settings.cfg,
## so both copies always show the same values.

signal closed # Return was pressed (the title screen uses this to show itself again)

const SETTINGS_PATH := "user://settings.cfg"
const TITLE_SCENE := "res://Scenes/Menus/title_menu.tscn"
const EMPTY_SLOT_TINT := Color(1, 1, 1, 0.35)
const LOCALES := ["en", "th"]

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

var debug_panel : Panel # only in debug builds (editor runs, "Export With Debug")
var screenshot : Image # taken when the menu opens in-game, before it covers the screen
var _pending_action : Callable # what Confirm does


func _ready() -> void:
	apply_saved_locale()
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
		var label_name := String(slider.name).trim_suffix("-slider")
		var label := slider.get_parent().get_node_or_null(label_name) as Label
		slider.accessibility_name = tr("%s volume") % tr(label.text if label else sliders[slider])
		slider.accessibility_description = tr("Left and right arrows change it.")

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

	_add_screen_reader_option()
	%English.pressed.connect(set_locale.bind("en"))
	%Thai.pressed.connect(set_locale.bind("th"))
	if OS.is_debug_build():
		_add_debug_page()

	# Screen readers: say what each part is, and announce questions.
	$Main/Return.accessibility_description = tr("Close the menu. Shortcut: Escape.")
	$Main/Exit.accessibility_description = tr("Back to the title screen, or quit from the title screen.")
	Accessibility.make_live(confirm_label, true)


## Shows the menu on the Settings page. In-game, call this before anything
## covers the screen so the save thumbnail is a picture of the story.
func open() -> void:
	screenshot = get_viewport().get_texture().get_image() if _story() else null
	$Main/Save.disabled = _story() == null # nothing to save on the title screen
	if debug_panel:
		$Main/Debug.visible = _story() != null
	_hide_confirm()
	_show_sub(setting_panel)
	visible = true
	Accessibility.focus($Main/Setting)

func close() -> void:
	_hide_confirm()
	_save_volumes() # also covers volumes changed with the keyboard
	visible = false
	closed.emit()


func _story() -> StoryPlayer:
	return get_tree().current_scene as StoryPlayer

func _show_sub(panel: Panel) -> void:
	for p in [setting_panel, save_panel, load_panel, debug_panel]:
		if p:
			p.visible = (p == panel)
	if panel == debug_panel:
		_fill_debug_page()
	elif panel != setting_panel:
		_refresh_slots()
	if visible:
		Accessibility.focus_first_button.call_deferred(panel)



# --- Language ---

## Switches the game's language and remembers it. Labels and buttons change
## by themselves; the story redraws its line (StoryPlayer._relocalize).
static func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale if locale in LOCALES else "en")
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # keep other sections
	cfg.set_value("general", "locale", TranslationServer.get_locale())
	cfg.save(SETTINGS_PATH)

static func apply_saved_locale() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	TranslationServer.set_locale(cfg.get_value("general", "locale", "en"))



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



# --- Screen reader ---

## "Screen reader: Auto / On / Off", added under the volume sliders. Auto
## turns the screen reader support on when one is found; On is for when it
## isn't found (some Linux desktops).
func _add_screen_reader_option() -> void:
	var row := HBoxContainer.new()
	row.name = "ScreenReader"
	var voice := setting_panel.get_node("Voice-slider") as Control
	row.position = Vector2(voice.position.x + 11, voice.position.y + voice.size.y + 40)
	row.add_theme_constant_override("separation", 24)
	var label := Label.new()
	label.text = "Screen reader" # auto-translated, so it follows language changes
	label.add_theme_font_size_override("font_size", 28)
	row.add_child(label)
	var pick := OptionButton.new()
	pick.name = "Mode"
	for text in ["Auto", "On", "Off"]:
		pick.add_item(text)
	pick.selected = Accessibility.get_mode()
	pick.accessibility_name = tr("Screen reader support")
	pick.accessibility_description = tr("Auto turns it on when a screen reader is found. On reads every line in full, lengthens timers and moves focus to choices.")
	pick.item_selected.connect(func(i): Accessibility.set_mode(i))
	row.add_child(pick)
	setting_panel.add_child(row)


# --- Debug (to show and test the story: jump anywhere, change meters and flags) ---

func _add_debug_page() -> void:
	var button := $Main/Load.duplicate(0) as Button # 0: without Load's click handler
	button.name = "Debug"
	button.text = "Debug" # auto-translated
	button.position.y += $Main/Load.position.y - $Main/Save.position.y # one step below Load
	button.accessibility_description = tr("Jump to scenes and minigames, change meters and flags.")
	button.pressed.connect(func(): _show_sub(debug_panel))
	$Main.add_child(button)

	debug_panel = Panel.new()
	debug_panel.name = "Sub4-debug"
	for prop in ["anchor_left", "anchor_top", "anchor_right", "anchor_bottom", "offset_left", "offset_top", "offset_right", "offset_bottom"]:
		debug_panel.set(prop, setting_panel.get(prop)) # same place and size as the Settings page
	debug_panel.visible = false
	add_child(debug_panel)
	move_child(debug_panel, confirm.get_index()) # under the Confirm popup

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	debug_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)

## Rebuilt every time the page opens, so it always shows the story's current state.
func _fill_debug_page() -> void:
	var column := debug_panel.find_child("Column", true, false) as VBoxContainer
	for child in column.get_children():
		child.queue_free()
	var story := _story()
	if story == null:
		return

	column.add_child(_debug_heading(tr("Jump to")))
	var games := []
	for id in story.graph.nodes:
		if story.graph.nodes[id].has("minigame"):
			games.append(id)
	games.sort()
	for id in games:
		var go := Button.new()
		go.text = tr("Minigame: %s (%s)") % [String(story.graph.nodes[id]["minigame"]).get_file().get_basename(), id]
		go.pressed.connect(_debug_jump.bind(id))
		column.add_child(go)
	var row := HBoxContainer.new()
	var field := LineEdit.new()
	field.placeholder_text = tr("node id, e.g. absent_1")
	field.accessibility_name = tr("Node id to jump to")
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var jump := Button.new()
	jump.text = tr("Go")
	jump.pressed.connect(func(): _debug_jump(field.text.strip_edges()))
	field.text_submitted.connect(func(text): _debug_jump(text.strip_edges()))
	row.add_child(field)
	row.add_child(jump)
	column.add_child(row)
	column.add_child(_debug_label(tr("Now at: %s") % story.current_node))

	column.add_child(_debug_heading(tr("Meters")))
	var meters : Dictionary = story.mode.get_meters()
	for meter in meters:
		var line := HBoxContainer.new()
		var label := _debug_label("%s  %d" % [meter, meters[meter]])
		label.custom_minimum_size.x = 220
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = meters[meter]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.accessibility_name = meter
		slider.value_changed.connect(func(v):
			story.debug_set_meters({meter: v})
			label.text = "%s  %d" % [meter, v])
		line.add_child(label)
		line.add_child(slider)
		column.add_child(line)

	column.add_child(_debug_heading(tr("Flags")))
	for flag in story.graph.flag_names():
		var box := CheckBox.new()
		box.text = flag
		box.button_pressed = story.flags.get(flag, false)
		box.toggled.connect(func(on): story.flags[flag] = on)
		column.add_child(box)

func _debug_jump(node: String) -> void:
	var story := _story()
	if story == null or not story.graph.has_entry(node):
		return
	close()
	story.debug_jump(node)

func _debug_heading(text: String) -> Label:
	var label := _debug_label(text)
	label.add_theme_font_size_override("font_size", 30)
	return label

func _debug_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	return label


# --- Save / load ---

func _on_save_slot(slot: int) -> void:
	if SaveGame.exists(slot):
		_ask(tr("Overwrite slot %d?") % slot, _save_to.bind(slot))
	else:
		_save_to(slot)

func _save_to(slot: int) -> void:
	SaveGame.write(slot, _story().get_save_data(), screenshot)
	_refresh_slots()

func _on_load_slot(slot: int) -> void:
	if not SaveGame.exists(slot):
		return
	if _story():
		_ask(tr("Load slot %d?\nUnsaved progress is lost.") % slot, SaveGame.load_slot.bind(get_tree(), slot))
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
				button.accessibility_name = tr("Slot %d: %s, saved %s") % [slot, data.get("character", ""), String(data.get("saved_at", "")).replace("T", " at ")]
			else:
				button.texture_normal = button.get_meta("empty_texture")
				button.stretch_mode = TextureButton.STRETCH_TILE
				button.modulate = EMPTY_SLOT_TINT if slots == load_slots else Color.WHITE
				label.text = tr("%d  Empty") % slot
				button.accessibility_name = tr("Slot %d: empty") % slot

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
		_ask(tr("Back to the title screen?\nUnsaved progress is lost."), get_tree().change_scene_to_file.bind(TITLE_SCENE))
	else:
		_ask(tr("Quit the game?"), get_tree().quit)

func _ask(question: String, action: Callable) -> void:
	confirm_label.text = question
	_pending_action = action
	confirm.visible = true
	Accessibility.say(confirm_label, question.replace("\n", " ") + " Confirm or Cancel.")
	Accessibility.focus($Confirm/Button)

func _on_confirm() -> void:
	var action := _pending_action
	_hide_confirm()
	if action.is_valid():
		action.call()

func _hide_confirm() -> void:
	confirm.visible = false
	confirm_label.text = tr("Are you sure?")
	_pending_action = Callable()
