class_name SaveGame
extends RefCounted
## Save slots on disk (user://saves/). A slot is a JSON file plus a screenshot.
## Loading works across scenes: load_slot() stores the data in `pending`,
## switches to the saved story scene, and StoryPlayer picks it up in _ready().

const DIR := "user://saves/"
const THUMB_SIZE := Vector2i(480, 270)

static var pending : Dictionary = {} # save waiting to be applied by the next StoryPlayer


static func json_path(slot: int) -> String:
	return DIR + "slot_%d.json" % slot

static func thumb_path(slot: int) -> String:
	return DIR + "slot_%d.png" % slot


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(json_path(slot))

static func read(slot: int) -> Dictionary:
	var text := FileAccess.get_file_as_string(json_path(slot))
	var data = JSON.parse_string(text)
	return data if data is Dictionary else {}

static func thumbnail(slot: int) -> Texture2D:
	if not FileAccess.file_exists(thumb_path(slot)):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(thumb_path(slot)))
	return ImageTexture.create_from_image(image) if image else null


static func write(slot: int, data: Dictionary, screenshot: Image) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var file := FileAccess.open(json_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Couldn't write save slot %d" % slot)
		return
	file.store_string(JSON.stringify(data, "\t"))
	if screenshot:
		var thumb := screenshot.duplicate() as Image
		thumb.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_BILINEAR)
		thumb.save_png(thumb_path(slot))


## Switches to the saved story scene; StoryPlayer restores the rest.
static func load_slot(tree: SceneTree, slot: int) -> void:
	var data := read(slot)
	if data.is_empty():
		push_error("Save slot %d is empty or broken" % slot)
		return
	pending = data
	tree.change_scene_to_file(data["scene"])
