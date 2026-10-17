extends Control
## Ulyn's "Ninety Unread". Sports day questions pop up on the desk faster
## than anyone could answer them (faster the higher his Busy). At 7:00 Mom
## calls; the only button is Decline. Results: "declined" (pressed it),
## "let_ring" (left it ringing until it stopped).

signal finished(result: String)

const MESSAGES := [
	"where are the cones??",
	"who has the storeroom key",
	"can I swap to the relay",
	"is the tent ours or 11/3's",
	"how many water bottles",
	"I can't come at 7am sorry",
	"which field is the long jump",
	"does the roster have my name",
	"are we wearing the yellow shirts",
	"who's bringing the speaker",
	"the whistle is missing",
	"can my friend volunteer too",
	"what time is the warm up",
	"Pim says ask you",
	"is lunch provided??",
	"sorry one more question",
]

const CARD_SIZE := Vector2(330, 64)
const SPAWN_EVERY_MIN := 0.5 # seconds between messages at Busy 100...
const SPAWN_EVERY_MAX := 1.6 # ...and at Busy 0
const MAX_CARDS := 14 # more than this and the oldest stays buried (still unread)
const CALL_FADE := 0.25

@onready var desk : Control = %Desk
@onready var clock : Label = %Clock
@onready var unread_label : Label = %Unread
@onready var call_panel : Control = %Call
@onready var decline : Button = %Decline
@onready var ring : AudioStreamPlayer = get_node_or_null("%Ring") # optional: add one to hear the call

var _before_call := 8.0 # seconds until 7:00
var _after_call := 8.0 # the game ends this long after the call starts
var _ring_time := 6.0
var _unread := 90
var _busy := 60.0

var _time := 0.0
var _spawn_wait := 0.0
var _call_started := false
var _call_left := 0.0
var _declined := false
var _done := false


## Called by StoryPlayer before the game shows.
func start(settings: Dictionary, meters: Dictionary, time_mult := 1.0) -> void:
	_before_call = settings.get("before_call", _before_call) * time_mult
	_after_call = settings.get("after_call", _after_call) * time_mult
	_ring_time = settings.get("ring_time", _ring_time) * time_mult
	_unread = settings.get("unread", _unread)
	_busy = meters.get("busy", _busy)


func _ready() -> void:
	call_panel.visible = false
	decline.pressed.connect(_on_decline)
	decline.accessibility_description = tr("Shortcut: D.")
	Accessibility.make_live(unread_label, true)
	_update_labels()
	Accessibility.say(unread_label, tr("The group chat. Messages keep coming in. Tab between them and press Enter to answer one."))
	for i in 3:
		_spawn_card.call_deferred() # after StoryPlayer has sized the desk


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	_spawn_wait -= delta
	if _spawn_wait <= 0.0:
		_spawn_card()
		_spawn_wait = lerpf(SPAWN_EVERY_MAX, SPAWN_EVERY_MIN, clampf(_busy / 100.0, 0.0, 1.0)) * randf_range(0.7, 1.3)

	if not _call_started and _time >= _before_call:
		_start_call()
	if call_panel.visible:
		_call_left -= delta
		if _call_left <= 0.0:
			_hang_up() # rang out
	if _call_started and _time >= _before_call + _after_call:
		_done = true
		finished.emit("declined" if _declined else "let_ring")
	_update_labels()


func _input(event: InputEvent) -> void:
	if _done or not call_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_D:
		_on_decline()
		get_viewport().set_input_as_handled()


# --- Messages ---

func _spawn_card() -> void:
	_unread += 1
	if desk.get_child_count() >= MAX_CARDS:
		return # buried under the pile: only the count goes up
	var card := Button.new()
	card.text = MESSAGES.pick_random() # auto-translated
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.clip_text = true
	var room := (desk.size - CARD_SIZE).max(Vector2.ZERO)
	card.position = Vector2(randf() * room.x, randf() * room.y)
	card.pressed.connect(_answer.bind(card))
	desk.add_child(card)
	if get_viewport().gui_get_focus_owner() == null and Accessibility.screen_reader_on():
		card.grab_focus()

func _answer(card: Button) -> void:
	_unread = maxi(_unread - 1, 0)
	var next := card.find_next_valid_focus()
	var had_focus := card.has_focus()
	card.queue_free()
	if had_focus and next and next != card and next.get_parent() == desk:
		next.grab_focus() # keyboard players land on the next message

func _update_labels() -> void:
	var minutes := 52 + int(_time * 8.0 / _before_call) # 6:52 -> 7:00 at the call, then on
	clock.text = "%d:%02d PM" % [6 + floori(minutes / 60.0), minutes % 60]
	unread_label.text = tr("%d unread") % _unread


# --- Mom's call ---

func _start_call() -> void:
	_call_started = true
	_call_left = _ring_time
	call_panel.modulate.a = 0.0
	call_panel.visible = true
	create_tween().tween_property(call_panel, "modulate:a", 1.0, CALL_FADE)
	if ring:
		ring.play()
	Accessibility.say(unread_label, tr("Mom is calling. Press D to decline, or let it ring."))

func _on_decline() -> void:
	if not call_panel.visible:
		return
	_declined = true
	_hang_up()

func _hang_up() -> void:
	call_panel.visible = false
	if ring:
		ring.stop()
