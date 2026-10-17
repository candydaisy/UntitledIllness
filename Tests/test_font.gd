extends SceneTree
## Noto everywhere: the shared font draws Latin and Thai, and nothing still
## points at the old Minecraft font.
## Run: godot --headless --path . -s res://Tests/test_font.gd

func _initialize() -> void:
	var font := load("res://Assets/Fonts/noto.tres") as Font
	if font == null:
		return fail("res://Assets/Fonts/noto.tres is missing")
	if not font.has_char(ord("A")):
		return fail("noto.tres has no Latin 'A'")
	if not _has_char_with_fallbacks(font, ord("ก")):
		return fail("noto.tres can't draw Thai 'ก' (fallback missing)")
	for path in _scene_files("res://Assets") + _scene_files("res://Scenes"):
		if "Minecraft.ttf" in FileAccess.get_file_as_string(path):
			return fail("%s still uses Minecraft.ttf" % path)
	print("PASS")
	quit(0)


func _has_char_with_fallbacks(font: Font, ch: int) -> bool:
	if font.has_char(ch):
		return true
	for f in font.fallbacks:
		if _has_char_with_fallbacks(f, ch):
			return true
	return false

func _scene_files(dir: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tres") or f.ends_with(".tscn"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out += _scene_files(dir.path_join(d))
	return out

func fail(reason: String) -> void:
	print("FAIL: ", reason)
	quit(1)
