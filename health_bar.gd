extends Node2D
class_name HealthBar2D

@export var health: Health
@export var bar_size: Vector2 = Vector2(48, 6)
@export var y_offset: float = -32.0

var _ratio: float = 1.0

func _ready() -> void:
	z_index = 1000
	z_as_relative = false
	# garante que fique acima da cabeça
	position.y = y_offset

	# auto-wire se você não arrastar no Inspector
	if health == null and get_parent().has_node("Health"):
		health = get_parent().get_node("Health") as Health

	if health == null:
		push_error("HealthBar2D: health não definido e não achei 'Health' no pai.")
		return

	# estado inicial
	_ratio = float(health.hp) / float(max(1, health.stats.max_hp))
	queue_redraw()

	# atualiza quando HP muda
	health.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current: int, max_hp: int) -> void:
	_ratio = float(current) / float(max(1, max_hp))
	queue_redraw()

func _draw() -> void:
	# barra centralizada no node
	var w := bar_size.x
	var h := bar_size.y
	var x := -w * 0.5
	var y := -h * 0.5

	# fundo
	draw_rect(Rect2(Vector2(x, y), Vector2(w, h)), Color(0, 0, 0, 0.6), true)

	# preenchimento
	draw_rect(Rect2(Vector2(x, y), Vector2(w * clampf(_ratio, 0.0, 1.0), h)), Color(0.2, 1.0, 0.2, 0.85), true)

	# borda
	draw_rect(Rect2(Vector2(x, y), Vector2(w, h)), Color(1, 1, 1, 0.5), false, 1.0)
