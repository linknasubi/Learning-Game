extends Node2D
class_name ScratchVFX

@export var range_px: float = 36.0
@export var cone_deg: float = 25.0
@export var duration: float = 0.08

var _time_left: float = 0.0
var _dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	visible = false
	set_process(false)

	z_as_relative = false
	z_index = 999

	
func play(dir: Vector2) -> void:
	var d: Vector2 = dir
	_dir = d.normalized() if d.length() > 0.001 else Vector2.RIGHT
	_time_left = duration
	visible = true
	set_process(true)
	queue_redraw()



func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		visible = false
		set_process(false)
		return
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	# alinha o desenho com a direção do ataque
	var ang0: float = _dir.angle()
	var half: float = deg_to_rad(cone_deg * 0.5)

	# aproxima o setor com poucos pontos
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)

	var steps := 10
	for i in range(steps + 1):
		var a := ang0 - half + (float(i) / float(steps)) * (half * 2.0)
		points.append(Vector2(cos(a), sin(a)) * range_px)

	# “fatiinha” translúcida
	draw_colored_polygon(points, Color(1, 1, 1, 0.18))

	# borda
	for i in range(1, points.size() - 1):
		draw_line(points[i], points[i + 1], Color(1, 1, 1, 0.6), 2.0)
