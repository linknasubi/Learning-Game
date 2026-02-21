extends Node2D
class_name ImpactRing

@export var duration: float = 0.14
@export var r0: float = 6.0
@export var r1: float = 28.0
@export var width: float = 2.0

var _t: float = 0.0

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k: float = clamp(_t / duration, 0.0, 1.0)
	var r: float = lerpf(r0, r1, k)
	var a: float = lerpf(0.8, 0.0, k)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1, 1, 1, a), width)
