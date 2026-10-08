class_name EmotionalWeight
extends RefCounted
## How much emotional pressure a character is carrying.

signal state_changed(state: State)

enum State { LOW, MEDIUM, HIGH, CRITICAL }

const THRESHOLDS := [0.30, 0.50, 0.80] # upper bound (% of max) of LOW, MEDIUM, HIGH

var value := 0.0
var max_value := 100.0
var state := State.LOW


func _init(start_value := 0.0, max_val := 100.0) -> void:
	max_value = max_val
	set_value(start_value)


func change(amount: float) -> void:
	set_value(value + amount)

func set_value(new_value: float) -> void:
	value = clampf(new_value, 0.0, max_value)
	var new_state := _state_for(value / max_value)
	if new_state != state:
		state = new_state
		state_changed.emit(state)


func _state_for(percent: float) -> State:
	for i in THRESHOLDS.size():
		if percent < THRESHOLDS[i]:
			return i as State
	return State.CRITICAL
