extends SceneTree
## Language setting: switching to Thai translates the interface and is saved;
## switching back restores English.
## Run: godot --headless --path . -s res://Tests/test_language.gd

func _initialize() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SettingMenu.SETTINGS_PATH)
	var before = cfg.get_value("general", "locale", "en") # put it back afterwards

	SettingMenu.set_locale("th")
	if TranslationServer.translate("Settings") != "ตั้งค่า":
		return fail("'Settings' in Thai is '%s'" % TranslationServer.translate("Settings"))
	if TranslationServer.translate("Back") != "กลับ":
		return fail("'Back' in Thai is '%s'" % TranslationServer.translate("Back"))
	if TranslationServer.translate("Overwrite slot %d?") % 2 == "Overwrite slot 2?":
		return fail("format strings aren't translated")
	cfg.load(SettingMenu.SETTINGS_PATH)
	if cfg.get_value("general", "locale", "") != "th":
		return fail("locale wasn't saved")

	SettingMenu.set_locale("en")
	if TranslationServer.translate("Settings") != "Settings":
		return fail("English didn't come back")

	SettingMenu.set_locale("th")
	TranslationServer.set_locale("en")
	SettingMenu.apply_saved_locale()
	if TranslationServer.get_locale() != "th":
		return fail("apply_saved_locale didn't restore 'th'")

	# The Thai / English buttons on the Settings page.
	var menu = load("res://Scenes/Menus/Setting.tscn").instantiate()
	root.add_child(menu)
	await process_frame # let _ready connect the buttons
	SettingMenu.set_locale("en")
	menu.get_node("%Thai").pressed.emit()
	if TranslationServer.get_locale() != "th":
		return fail("the Thai button didn't switch to Thai")
	menu.get_node("%English").pressed.emit()
	if TranslationServer.get_locale() != "en":
		return fail("the English button didn't switch back")
	menu.queue_free()

	SettingMenu.set_locale(before)
	print("PASS")
	quit(0)

func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
