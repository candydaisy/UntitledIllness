extends Control
## Ulyn types a text to Mom on Tan's balcony. Any key (or a tap on the
## message) types the next letter; letters delete themselves from the end,
## faster the higher his Unsaid. Send while something is still written.
## Results: "sent" (pressed Send or Enter with text), "deleted" (the box
## emptied again, Escape, or the timer ran out).

signal finished(result: String)

const DELETE_EVERY := 0.6 # seconds per deleted letter, at Unsaid 0
const DELETE_UNSAID := 0.005 # seconds faster per point of Unsaid
const DELETE_MIN := 0.15

@onready var message : Label = %Message
@onready var prompt : Label = %Prompt
@onready var send : Button = %Send

var _seconds := 15.0
var _text := "hi mom. sorry. i'm eating."
var _unsaid := 50.0
var _time_left := 0.0
var _typed := 0 # letters showing
var _delete_timer := 0.0
var _started := false
var _done := false


func start(settings: Dictionary, meters: Dictionary, time_mult := 1.0) -> void:
	_seconds = settings.get("seconds", _seconds) * time_mult
	_text = settings.get("message", _text)
	_unsaid = meters.get("unsaid", _unsaid)


func _ready() -> void:
	_text = tr(_text)
	_time_left = _seconds
	send.pressed.connect(press_send)
	send.focus_mode = Control.FOCUS_NONE # keys are for typing
	message.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			type_letter())
	_show()
	prompt.text = tr("Type to Mom. Press Enter to send.")
	Accessibility.make_live(prompt, true)
	Accessibility.say(prompt, tr("Type a message to Mom. Any key types. It keeps deleting itself. Press Enter to send or Escape to give up."))


func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		_finish("deleted")
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		press_send()
	else:
		type_letter()
	get_viewport().set_input_as_handled()


func type_letter() -> void:
	if _done:
		return
	_started = true
	_typed = mini(_typed + 1, _text.length())
	_show()


func press_send() -> void:
	if _typed > 0:
		_finish("sent")


func _process(delta: float) -> void:
	if _done:
		return
	if _started:
		_delete_timer += delta
		var every := maxf(DELETE_EVERY - DELETE_UNSAID * _unsaid, DELETE_MIN)
		while _delete_timer >= every and _typed > 0:
			_delete_timer -= every
			_typed -= 1
			_show()
		if _typed == 0:
			_finish("deleted")
			return
	_time_left -= delta
	if _time_left <= 0.0:
		_finish("deleted")


func _show() -> void:
	message.text = _text.substr(0, _typed) + "|"
	send.disabled = _typed == 0


func _finish(result: String) -> void:
	if _done:
		return
	_done = true
	finished.emit(result)
