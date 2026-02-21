extends Area2D
class_name Arrow

@export var speed: float = 700.0
@export var lifetime: float = 1.2

var damage: int = 1
var shooter: Node2D
var dir: Vector2 = Vector2.RIGHT
var _trail: PackedVector2Array = PackedVector2Array()
@export var trail_len := 6
@export var trail_step := 0.02
var _trail_t := 0.0

func _ready() -> void:
	# Se o Arrow colidir com algo, chamamos handler
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_trail_t += delta
	if _trail_t >= trail_step:
		_trail_t = 0.0
		_trail.append(to_local(global_position))
		while _trail.size() > trail_len:
			_trail.remove_at(0)
		queue_redraw()
	global_position += dir * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		

func _on_body_entered(body: Node) -> void:
	# não acertar o próprio shooter
	print("[ARROW] hit:", body.name, " groups=", body.get_groups())


	if body == shooter:
		return

	# só acertar inimigos
	if body.is_in_group("enemies") and body.has_node("Health"):
		var h: Health = body.get_node("Health")
		h.take_damage(damage, shooter)
		queue_free()


func _draw() -> void:
	if _trail.size() >= 2:
		for i in range(_trail.size() - 1):
			var a: Vector2 = _trail[i]
			var b: Vector2 = _trail[i + 1]
			# espessura decai
			var t: float = float(i) / float(max(1, _trail.size() - 2))
			draw_line(a, b, Color(1,1,1, 0.35 * t), 2.0)
