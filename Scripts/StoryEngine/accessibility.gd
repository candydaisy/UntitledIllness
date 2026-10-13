class_name Accessibility
extends RefCounted
## Screen reader support, using Godot's built-in accessibility (AccessKit).
## Godot exposes every Control to screen readers (NVDA, VoiceOver, Orca)
## automatically when one is running ("Accessibility Support" = Auto in Project
## Settings). This class adds what a visual novel needs on top: spoken lines
## without markup, and announcements for things that only appear on screen.
##
## To test without a screen reader, run the game with:  -- --screen-reader

const NOTICE := "\\{([^{}|]+)\\|([A-Za-z0-9_]+)\\}" # {shown text|FlagName}

static var _notice := RegEx.create_from_string(NOTICE)
static var _bbcode := RegEx.create_from_string("\\[[^\\]]*\\]")


const SETTINGS_PATH := "user://settings.cfg" # shared with the settings menu
enum Mode { AUTO, ON, OFF }

static var _linux_checked := false
static var _linux_reader := false


## True when the game should act for a screen reader: the "Screen reader"
## setting is On, or it's Auto and a screen reader was found (or the game was
## started with --screen-reader).
static func screen_reader_on() -> bool:
	if "--screen-reader" in OS.get_cmdline_user_args():
		return true
	match get_mode():
		Mode.ON: return true
		Mode.OFF: return false
	return _detected()

## Godot's own check (sometimes unknown on Linux), then on Linux the system's
## accessibility bus, which knows when Orca is running. Checked once per launch.
static func _detected() -> bool:
	if DisplayServer.accessibility_screen_reader_active() == 1:
		return true
	if OS.get_name() == "Linux":
		if not _linux_checked:
			_linux_checked = true
			var out := []
			var code := OS.execute("gdbus", ["call", "--session", "--dest", "org.a11y.Bus",
				"--object-path", "/org/a11y/bus", "--method", "org.freedesktop.DBus.Properties.Get",
				"org.a11y.Status", "ScreenReaderEnabled"], out)
			_linux_reader = code == 0 and not out.is_empty() and "true" in str(out[0])
		return _linux_reader
	return false


static func get_mode() -> Mode:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	return cfg.get_value("accessibility", "screen_reader", Mode.AUTO)

static func set_mode(mode: Mode) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("accessibility", "screen_reader", mode)
	cfg.save(SETTINGS_PATH)

## Godot can't talk to screen readers at all (e.g. a Linux build without
## AccessKit). Everything here still works, but nothing gets read aloud.
static func supported() -> bool:
	return AccessibilityServer.is_supported()


## Focuses `control` only while a screen reader is running (see focus_first_button).
static func focus(control: Control) -> void:
	if control and screen_reader_on():
		control.grab_focus.call_deferred()


## Story text -> what a screen reader should say: no BBCode, no {detail|Flag}
## markup, and no *asterisks* around narration.
static func speech(text: String) -> String:
	var out := _notice.sub(text, "$1", true)
	out = _bbcode.sub(out, "", true)
	out = out.replace("*", "")
	return out.strip_edges()

## [{text, flag}] for every detail to notice in a line.
static func notices(text: String) -> Array:
	var found := []
	for m in _notice.search_all(text):
		found.append({"text": m.get_string(1), "flag": m.get_string(2)})
	return found


## Makes a Control announce its accessibility name whenever it changes.
static func make_live(control: Control, urgent := false) -> void:
	if control == null:
		return
	control.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE if urgent else AccessibilityServer.LIVE_POLITE

## Sets what a Control says, and (for live Controls) announces it.
static func say(control: Control, text: String) -> void:
	if control == null:
		return
	control.accessibility_name = text
	control.queue_accessibility_update()


## With a screen reader running, focuses the first visible, enabled button
## under `root`, so the player lands somewhere useful when a menu opens.
## (Without one, focus is left alone so no focus outline appears; keyboard
## players can still press Tab.)
static func focus_first_button(root: Node) -> bool:
	if not screen_reader_on():
		return false
	for child in root.find_children("*", "BaseButton", true, false):
		var b := child as BaseButton
		if b.is_visible_in_tree() and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
			return true
	return false
