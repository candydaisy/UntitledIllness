extends Control
## Elysia fixes her face in the front camera before she sends "good morning".
## Drag Smile and Eyes until the face matches the faint "perfect" outline.
## The higher her Mask, the more the outline drifts, so it never holds still.
## Results: "perfect" (took it while matched), "real" (took it as it was, or
## the timer ran out unmatched).

signal finished(result: String)

const TOLERANCE := 0.08 # how close both sliders must be to the outline
const DRIFT_MASK := 0.003 # outline drift per point of Mask (Mask 100 = ±0.3)

@onready var face : Control = %Face
@onready var smile : Range = %Smile
@onready var eyes : Range = %Eyes
@onready var prompt : Label = %Prompt
@onready var take : Button = %Take

var _seconds := 12.0
var _mask := 50.0
var _time_left := 0.0
var _t := 0.0
var _done := false
var _target := Vector2(0.8, 0.7) # x = smile, y = eyes
var _was_matched := false


func start(settings: Dictionary, meters: Dictionary, time_mult := 1.0) -> void:
	_seconds = settings.get("seconds", _seconds) * time_mult
	_mask = meters.get("mask", _mask)


func _ready() -> void:
	_time_left = _seconds
	for s in [smile, eyes]:
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
		s.value = 0.3 # tired face
		s.value_changed.connect(func(_v): face.queue_redraw())
	face.draw.connect(_draw_face)
	take.pressed.connect(func(): _finish(result()))
	prompt.text = tr("Match the outline. Then take it.")
	Accessibility.make_live(prompt)
	Accessibility.say(prompt, tr("Fix your face before the photo. Move Smile and Eyes until it says perfect, then press Take it."))
	smile.grab_focus()


func _input(event: InputEvent) -> void:
	if not _done and event.is_action_pressed("ui_cancel"):
		_finish(result())
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var drift := DRIFT_MASK * _mask
	target_at(Vector2(0.8 + sin(_t * 1.3) * drift * 0.6, 0.7 + sin(_t * 0.9 + 1.0) * drift))
	var matched := is_matched()
	if matched != _was_matched:
		_was_matched = matched
		prompt.text = tr("Perfect.") if matched else tr("Match the outline. Then take it.")
	face.queue_redraw()
	_time_left -= delta
	if _time_left <= 0.0:
		_finish(result())


func target_at(target: Vector2) -> void:
	_target = target.clamp(Vector2.ZERO, Vector2.ONE)


func is_matched() -> bool:
	return absf(smile.value - _target.x) < TOLERANCE and absf(eyes.value - _target.y) < TOLERANCE


func result() -> String:
	return "perfect" if is_matched() else "real"


func _draw_face() -> void:
	var c := face.size / 2.0
	var r := minf(face.size.x, face.size.y) * 0.45
	face.draw_circle(c, r, Color(1, 1, 1, 0.08))
	face.draw_arc(c, r, 0, TAU, 64, Color.WHITE, 3.0)
	_draw_features(c, r, _target, Color(1, 0.85, 0.4, 0.45), 6.0) # the "perfect" outline
	_draw_features(c, r, Vector2(smile.value, eyes.value), Color.WHITE, 3.0)


## Eyes: ellipses whose height follows "eyes". Mouth: a curve that frowns at 0
## and smiles at 1.
func _draw_features(c: Vector2, r: float, v: Vector2, col: Color, width: float) -> void:
	for side in [-1, 1]:
		var e := c + Vector2(side * r * 0.38, -r * 0.2)
		var h := lerpf(0.02, 0.16, v.y) * r
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24.0
			pts.append(e + Vector2(cos(a) * r * 0.14, sin(a) * h))
		face.draw_polyline(pts, col, width)
	var bend := lerpf(-0.18, 0.25, v.x) * r
	var mouth := PackedVector2Array()
	for i in 17:
		var x := lerpf(-0.4, 0.4, i / 16.0)
		mouth.append(c + Vector2(x * r, r * 0.4 + bend * (1.0 - pow(x / 0.4, 2))))
	face.draw_polyline(mouth, col, width)


func _finish(res: String) -> void:
	if _done:
		return
	_done = true
	finished.emit(res)
