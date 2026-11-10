extends Control
## Kay waters the garden. Hold Space, the mouse or the screen to pour, let go
## at the line. The heavier his Weight, the more his hand shakes and the more
## keeps dripping after he lets go, so it's easy to overshoot. The soil is
## already damp: "Leave it" is what Ms. Noi told him to do.
## Results: "left_it" (never poured), "right" (stopped near the line),
## "drowned" (went past it).

signal finished(result: String)

const POUR := 0.25 # per second while holding
const SHAKE_WEIGHT := 0.012 # pour speed wobble per point of Weight
const DRIP_WEIGHT := 0.0012 # extra soil water after letting go, per point of Weight
const TOLERANCE := 0.06 # how far from the line still counts as "right"
const START := 0.35 # "always a little damp"
const HAND_SHAKE := 0.15 # pixels the bar shakes per point of Weight while pouring

@onready var soil : ProgressBar = %Soil
@onready var line_mark : ColorRect = %Line
@onready var prompt : Label = %Prompt
@onready var skip : Button = %Skip

var _seconds := 10.0
var _line := 0.6
var _weight := 50.0
var _time_left := 0.0
var _holding := false
var _poured := false
var _done := false
var _t := 0.0
var _bar_pos := Vector2.ZERO


func start(settings: Dictionary, meters: Dictionary, time_mult := 1.0) -> void:
	_seconds = settings.get("seconds", _seconds) * time_mult
	_line = settings.get("line", _line)
	_weight = meters.get("weight", _weight)


func _ready() -> void:
	_time_left = _seconds
	soil.min_value = 0.0
	soil.max_value = 1.0
	soil.step = 0.0
	soil.value = START
	soil.show_percentage = false
	line_mark.position.y = soil.size.y * (1.0 - _line) - line_mark.size.y / 2.0 # Line is a child of Soil
	var how := tr("Hold the screen") if DisplayServer.is_touchscreen_available() else tr("Hold SPACE")
	prompt.text = tr("%s to water. Stop at the line.") % how
	skip.pressed.connect(func(): _finish(_judge()))
	skip.focus_mode = Control.FOCUS_NONE # Space is for pouring, not for this button
	Accessibility.make_live(prompt, true)
	Accessibility.say(prompt, tr("The soil is already damp. %s to water and let go at the line, or press Escape to leave it.") % how)


func _input(event: InputEvent) -> void:
	if _done or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		_finish(_judge())
	elif _is_press(event):
		if event is InputEventMouseButton and skip.get_global_rect().has_point(event.position):
			return # let the button take the click
		if not _holding:
			_bar_pos = soil.position # the root is resized after _ready, so grab it here
		_holding = true
		_poured = true
	elif _is_release(event):
		release()
	else:
		return
	get_viewport().set_input_as_handled()


## Letting go: what's still in the can drips in, then it's judged.
func release() -> void:
	if not _holding:
		return
	_holding = false
	soil.position = _bar_pos
	soil.value += DRIP_WEIGHT * _weight
	if soil.value >= _line - TOLERANCE:
		_finish(_judge())


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _holding:
		var wobble := sin(_t * 9.0) * SHAKE_WEIGHT * _weight # the hand speeds up and slows down
		soil.value += maxf(POUR * (1.0 + wobble), 0.02) * delta
		soil.position = _bar_pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * HAND_SHAKE * _weight
		if soil.value > _line + TOLERANCE:
			_finish("drowned")
			return
	_time_left -= delta
	if _time_left <= 0.0:
		_finish(_judge())


func _judge() -> String:
	if not _poured:
		return "left_it"
	return "drowned" if soil.value > _line + TOLERANCE else "right"


func _finish(result: String) -> void:
	if _done:
		return
	_done = true
	_holding = false
	finished.emit(result)


func _is_press(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)

func _is_release(event: InputEvent) -> bool:
	return event.is_action_released("ui_accept") \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed)
