extends Node2D
class_name XpBar2D

@export var leveling: Leveling
@export var bar_size: Vector2 = Vector2(40, 4) # menor que a verde
@export var y_offset: float = -24.0             # logo abaixo da verde (-32)

var _ratio: float = 0.0

func _ready() -> void:
	z_index = 1000
	z_as_relative = true
	position.y = y_offset

	# auto-wire se você não arrastar no Inspector
	if leveling == null and get_parent().has_node("Leveling"):
		leveling = get_parent().get_node("Leveling") as Leveling

	if leveling == null:
		push_error("XpBar2D: leveling não definido e não achei 'Leveling' no pai.")
		return

	# estado inicial
	var to_next: int = maxi(1, leveling.xp_to_next())

	_ratio = float(leveling.xp) / float(to_next)

	queue_redraw()

	# atualiza quando XP muda
	leveling.xp_changed.connect(_on_xp_changed)

func _on_xp_changed(current: int, to_next: int) -> void:
	_ratio = float(current) / float(max(1, to_next))
	queue_redraw()

func _draw() -> void:
	var w := bar_size.x
	var h := bar_size.y
	var x := -w * 0.5
	var y := -h * 0.5

	# fundo
	draw_rect(Rect2(Vector2(x, y), Vector2(w, h)), Color(0, 0, 0, 0.6), true)

	# preenchimento (azul)
	draw_rect(
		Rect2(Vector2(x, y), Vector2(w * clampf(_ratio, 0.0, 1.0), h)),
		Color(0.25, 0.55, 1.0, 0.9),
		true
	)

	# borda
	draw_rect(Rect2(Vector2(x, y), Vector2(w, h)), Color(1, 1, 1, 0.5), false, 1.0)
