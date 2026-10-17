extends Control
## Kay's "get out of bed". Hold Space, the mouse or the screen to sit up; let go
## and he sinks back. The heavier his Weight, the slower he rises and the faster
## he sinks. "max_progress" below 1 makes it impossible (Chapter 5).
## Results: "won" (sat up), "tried" (alarm ran out while trying), "gave_up"
## (stopped pressing, or "Stay in bed").

signal finished(result: String)

const RISE := 0.45 # per second while holding, at Weight 0
const RISE_WEIGHT := 0.003 # rise lost per point of Weight
const SINK := 0.2 # per second while not holding, at Weight 0
const SINK_WEIGHT := 0.004
const TAP := 0.03 # each press gives a small push, so tapping works too
const STRAIN_SHAKE := 6.0 # pixels the bar shakes when it can't go higher

@onready var progress : Range = %Progress
@onready var alarm : Label = %Alarm
@onready var prompt : Label = %Prompt
@onready var skip : Button = %Skip

var _seconds := 12.0 # until the alarm gives up
var _max_progress := 1.0
var _give_up_after := 3.0 # seconds without pressing = gave up
var _clock := "6:30"
var _weight := 50.0
var _time_left := 0.0
var _idle := 0.0
var _holding := false
var _tried := false # pressed at least once
var _done := false
var _straining := false # at max_progress and still holding: the bar shakes
var _bar_pos := Vector2.ZERO # where the bar sits when it isn't shaking


## Called by StoryPlayer before the game shows. time_mult stretches the
## timers (screen reader players get longer).
func start(settings: Dictionary, meters: Dictionary, time_mult := 1.0) -> void:
	_seconds = settings.get("seconds", _seconds) * time_mult
	_max_progress = settings.get("max_progress", _max_progress)
	_give_up_after = settings.get("give_up_after", _give_up_after) * time_mult
	_clock = settings.get("clock", _clock)
	_weight = meters.get("weight", _weight)


func _ready() -> void:
	_time_left = _seconds
	progress.min_value = 0.0
	progress.max_value = 1.0
	progress.step = 0.0
	progress.value = 0.0
	if progress is ProgressBar:
		progress.show_percentage = false

	alarm.text = _clock
	var how := tr("Hold the screen") if DisplayServer.is_touchscreen_available() else tr("Hold SPACE")
	prompt.text = tr("%s to get up") % how
	skip.pressed.connect(_finish.bind("gave_up"))
	skip.focus_mode = Control.FOCUS_NONE # Space is for getting up, not for this button
	Accessibility.make_live(prompt, true)
	Accessibility.say(prompt, tr("The alarm is ringing. %s to get up, or press Escape to stay in bed.") % how)


func _input(event: InputEvent) -> void:
	if _done or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		_finish("gave_up")
	elif _is_press(event):
		if event is InputEventMouseButton and skip.get_global_rect().has_point(event.position):
			return # let the button take the click
		_holding = true
		_tried = true
		progress.value = minf(progress.value + TAP, _max_progress)
	elif _is_release(event):
		_holding = false
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _done:
		return
	if _holding:
		_idle = 0.0
		progress.value = minf(progress.value + maxf(RISE - RISE_WEIGHT * _weight, 0.05) * delta, _max_progress)
	else:
		progress.value -= (SINK + SINK_WEIGHT * _weight) * delta
		if _tried:
			_idle += delta
	var straining := _holding and progress.value >= _max_progress - 0.001 and _max_progress < 1.0
	if straining and not _straining:
		_bar_pos = progress.position
	elif _straining and not straining:
		progress.position = _bar_pos
	_straining = straining
	if straining:
		progress.position = _bar_pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * STRAIN_SHAKE
	alarm.visible = fmod(_time_left, 1.0) > 0.4 # blinks once a second

	_time_left -= delta
	if progress.value >= 1.0:
		_finish("won")
	elif _idle >= _give_up_after:
		_finish("gave_up")
	elif _time_left <= 0.0:
		_finish("tried" if _tried else "gave_up")


func _finish(result: String) -> void:
	if _done:
		return
	_done = true
	finished.emit(result)


func _is_press(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)

func _is_release(event: InputEvent) -> bool:
	return event.is_action_released("ui_accept") \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed)
