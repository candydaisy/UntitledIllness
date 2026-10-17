extends Control
## Elysia's slime mold maze. The player drops oat flakes in a maze; the slime
## spreads through every corridor at once, then pulls back to only the
## shortest paths that link the flakes, like the Tokyo rail experiment.
## Now and then "Is someone on the path?" pops up (more often the higher her
## Mask). Results: "absorbed" (never pressed it), "checked" (pressed it).

signal finished(result: String)

const MAZE := [ # # wall, . open, S where the slime starts
	"###############",
	"S...#.....#...#",
	"#.#.#.###.#.#.#",
	"#.#...#...#.#.#",
	"#.###.#.###.#.#",
	"#...#...#.....#",
	"#.#.#####.###.#",
	"#.#.......#...#",
	"###############",
]
const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const MOVE_KEYS := {"ui_right": Vector2i.RIGHT, "ui_left": Vector2i.LEFT, "ui_down": Vector2i.DOWN, "ui_up": Vector2i.UP}

const SPREAD_SPEED := 6.0 # cells of distance per second
const RETRACT_TIME := 1.5
const HOLD_TIME := 1.5 # the finished network stays up this long
const CHECK_SHOWN := 2.0 # seconds the check button stays up
const CHECK_EVERY_MIN := 2.0 # at Mask 100...
const CHECK_EVERY_MAX := 7.0 # ...and at Mask 0

const WALL := Color(0.08, 0.05, 0.03, 0.85)
const FLOOR := Color(0.35, 0.25, 0.15, 0.35)
const SLIME := Color(1.0, 0.85, 0.2)
const FLAKE := Color(0.95, 0.88, 0.7)
const CURSOR := Color(1, 1, 1, 0.8)

enum Phase { PLACING, SPREADING, RETRACTING, DONE }

@onready var board : Control = %Board
@onready var prompt : Label = %Prompt
@onready var check : Button = %Check

var _flakes_total := 3
var _mask := 50.0
var _time_mult := 1.0

var _start := Vector2i.ZERO
var _open := {} # Vector2i -> true
var _dist := {} # Vector2i -> steps from the start
var _parent := {} # Vector2i -> the cell it was reached from (for shortest paths)
var _max_dist := 0
var _flakes : Array[Vector2i] = []
var _keep := {} # cells on the shortest paths, kept after retracting
var _cursor := Vector2i(1, 1)

var _phase := Phase.PLACING
var _spread := 0.0 # how far the slime has spread, in steps
var _phase_time := 0.0
var _check_wait := 0.0 # until the check button next shows
var _check_left := 0.0 # while it's showing
var _checked := false
var _done := false


## Called by StoryPlayer before the game shows.
func start(settings: Dictionary, meters: Dictionary, time_mult := 1.0) -> void:
	_flakes_total = settings.get("flakes", _flakes_total)
	_mask = meters.get("mask", _mask)
	_time_mult = time_mult


func _ready() -> void:
	for y in MAZE.size():
		for x in MAZE[y].length():
			var c : String = MAZE[y][x]
			if c != "#":
				_open[Vector2i(x, y)] = true
			if c == "S":
				_start = Vector2i(x, y)
	_find_paths()

	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_input)
	check.visible = false
	check.focus_mode = Control.FOCUS_NONE # Enter places flakes; C presses this
	check.pressed.connect(_on_check)
	_check_wait = _next_check()
	Accessibility.make_live(prompt, true)
	_update_prompt()
	Accessibility.say(prompt, "A maze on the bark. The slime mold starts on the left. Drop %d oat flakes: click a spot, or move with the arrow keys and press Enter." % _flakes_total)


## Breadth-first search from the start: steps to every cell, and the way back.
func _find_paths() -> void:
	_dist = {_start: 0}
	_parent = {}
	var queue : Array[Vector2i] = [_start]
	while not queue.is_empty():
		var cell : Vector2i = queue.pop_front()
		for d in DIRS:
			var next : Vector2i = cell + d
			if _open.has(next) and not _dist.has(next):
				_dist[next] = _dist[cell] + 1
				_parent[next] = cell
				_max_dist = maxi(_max_dist, _dist[next])
				queue.append(next)


func _process(delta: float) -> void:
	if _done:
		return
	_tick_check(delta)
	_phase_time += delta
	match _phase:
		Phase.SPREADING:
			_spread += SPREAD_SPEED * delta
			if _spread >= _max_dist:
				_keep_shortest_paths()
				_set_phase(Phase.RETRACTING)
				Accessibility.say(prompt, "It reached every flake. Now it pulls back to the shortest paths between them.")
		Phase.RETRACTING:
			if _phase_time >= RETRACT_TIME:
				_set_phase(Phase.DONE)
		Phase.DONE:
			if _phase_time >= HOLD_TIME:
				_done = true
				finished.emit("checked" if _checked else "absorbed")
	board.queue_redraw()


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0
	_update_prompt()


func _keep_shortest_paths() -> void:
	_keep = {_start: true}
	for flake in _flakes:
		var cell := flake
		while cell != _start:
			_keep[cell] = true
			cell = _parent[cell]


# --- Placing flakes ---

func _on_board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _cell_at(event.position)
		if _open.has(cell):
			_cursor = cell
			_place(cell)
		board.accept_event()

func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_C and check.visible:
		_on_check()
	elif _phase == Phase.PLACING and event.is_action_pressed("ui_accept"):
		_place(_cursor)
	elif _phase == Phase.PLACING and MOVE_KEYS.keys().any(func(a): return event.is_action_pressed(a)):
		for action in MOVE_KEYS:
			if event.is_action_pressed(action):
				_move_cursor(MOVE_KEYS[action])
				break
	else:
		return
	get_viewport().set_input_as_handled()

func _move_cursor(d: Vector2i) -> void:
	var next := _cursor + d
	if next.y >= 0 and next.y < MAZE.size() and next.x >= 0 and next.x < MAZE[0].length():
		_cursor = next
	Accessibility.say(prompt, "Column %d, row %d: %s." % [_cursor.x + 1, _cursor.y + 1, _describe(_cursor)])

func _describe(cell: Vector2i) -> String:
	if cell == _start:
		return "the slime mold"
	if cell in _flakes:
		return "oat flake"
	return "open" if _open.has(cell) else "wall"

func _place(cell: Vector2i) -> void:
	if _phase != Phase.PLACING or not _open.has(cell) or cell == _start or cell in _flakes:
		return
	_flakes.append(cell)
	_update_prompt()
	if _flakes.size() >= _flakes_total:
		_set_phase(Phase.SPREADING)
		Accessibility.say(prompt, "All flakes down. The slime mold spreads through every corridor at once.")
	else:
		Accessibility.say(prompt, "Flake dropped. %d left." % (_flakes_total - _flakes.size()))

func _update_prompt() -> void:
	match _phase:
		Phase.PLACING:
			var left := _flakes_total - _flakes.size()
			prompt.text = "Tap to drop oat flakes (%d left)" % left
		Phase.SPREADING:
			prompt.text = "It's looking for them..."
		_:
			prompt.text = "It found the shortest way."


# --- Checking the path ---

func _next_check() -> float:
	return lerpf(CHECK_EVERY_MAX, CHECK_EVERY_MIN, clampf(_mask / 100.0, 0.0, 1.0)) * randf_range(0.8, 1.2) * _time_mult

func _tick_check(delta: float) -> void:
	if _phase == Phase.DONE:
		check.visible = false
		return
	if check.visible:
		_check_left -= delta
		if _check_left <= 0.0:
			check.visible = false
			_check_wait = _next_check()
	else:
		_check_wait -= delta
		if _check_wait <= 0.0:
			check.visible = true
			_check_left = CHECK_SHOWN * _time_mult
			Accessibility.say(prompt, "Is someone on the path? Press C to look, or keep going.")

func _on_check() -> void:
	_checked = true
	check.visible = false
	_check_wait = _next_check()
	Accessibility.say(prompt, "Nobody's there.")


# --- Drawing ---

func _cell_size() -> float:
	return minf(board.size.x / MAZE[0].length(), board.size.y / MAZE.size())

func _origin() -> Vector2: # centers the maze in the board
	return (board.size - Vector2(MAZE[0].length(), MAZE.size()) * _cell_size()) / 2.0

func _cell_at(pos: Vector2) -> Vector2i:
	var p := (pos - _origin()) / _cell_size()
	return Vector2i(floori(p.x), floori(p.y))

func _draw_board() -> void:
	var s := _cell_size()
	var o := _origin()
	for y in MAZE.size():
		for x in MAZE[y].length():
			var cell := Vector2i(x, y)
			var rect := Rect2(o + Vector2(x, y) * s, Vector2(s, s))
			board.draw_rect(rect, FLOOR if _open.has(cell) else WALL)
			var a := _slime_alpha(cell)
			if a > 0.0:
				board.draw_rect(rect.grow(-s * 0.12), Color(SLIME, a))
	for flake in _flakes:
		board.draw_circle(o + (Vector2(flake) + Vector2(0.5, 0.5)) * s, s * 0.22, FLAKE)
	if _phase == Phase.PLACING:
		board.draw_rect(Rect2(o + Vector2(_cursor) * s, Vector2(s, s)), CURSOR, false, 3.0)

## How visible the slime is on a cell: grows in as it spreads, and fades
## off the cells that aren't on a shortest path while it retracts.
func _slime_alpha(cell: Vector2i) -> float:
	if not _dist.has(cell):
		return 0.0
	if cell == _start:
		return 1.0
	if _phase == Phase.PLACING:
		return 0.0
	var a := clampf(_spread - _dist[cell] + 1.0, 0.0, 1.0)
	if _phase == Phase.RETRACTING and not _keep.has(cell):
		a *= 1.0 - clampf(_phase_time / RETRACT_TIME, 0.0, 1.0)
	elif _phase == Phase.DONE and not _keep.has(cell):
		a = 0.0
	return a
