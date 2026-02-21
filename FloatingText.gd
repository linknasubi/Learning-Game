extends Label
class_name FloatingText

@export var rise_px: float = 42.0
@export var duration: float = 0.55

var _t: float = 0.0
var _start_pos: Vector2

func play(world_pos: Vector2, msg: String) -> void:
	text = msg
	global_position = world_pos
	_start_pos = world_pos
	_t = 0.0
	visible = true
	modulate.a = 1.0

func _process(delta: float) -> void:
	_t += delta
	var k: float = clamp(_t / duration, 0.0, 1.0)

	# sobe e some
	global_position = _start_pos + Vector2(0.0, -rise_px * k)
	modulate.a = 1.0 - k

	if k >= 1.0:
		queue_free()
