extends Control

@export var blink_time := 0.1

var tween: Tween

func blink() -> void:
	if tween:
		tween.kill()
	
	visible = true
	modulate.a = 0.0
	
	tween = create_tween()
	tween.tween_interval(blink_time)
	tween.tween_property(self, "modulate:a", 1.0, blink_time)
	tween.tween_interval(blink_time)
	tween.tween_property(self, "modulate:a", 0.0, blink_time) 
	tween.tween_interval(blink_time)
	tween.tween_callback(func(): visible = false)
