extends Control
class_name ModeCardsHUD

@export var active_mode: int = 1

@export var card_size: Vector2 = Vector2(120, 52)
@export var card_gap: float = 12.0
@export var cards_count: int = 4
@export var bottom_margin: float = 18.0
@export var rise_px: float = 14.0

var labels: Dictionary[int, String] = {
	1: "1  Spawn",
	2: "2  Comandar",
	3: "3  ...",
	4: "4  ..."
}

func _ready() -> void:
	# garante que esse Control ocupa a tela inteira
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_active_mode(v: int) -> void:
	active_mode = v
	queue_redraw()



func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var total_w: float = (card_size.x * float(cards_count)) + (card_gap * float(cards_count - 1))
	var start_x: float = (viewport_size.x - total_w) * 0.5
	var base_y: float = viewport_size.y - bottom_margin - card_size.y

	for i in range(cards_count):
		var mode: int = i + 1
		var x: float = start_x + float(i) * (card_size.x + card_gap)
		var y: float = base_y

		var is_active: bool = (mode == active_mode)




		if is_active:
			y -= rise_px

		var rect: Rect2 = Rect2(Vector2(x, y), card_size)

		var bg_a: float = 0.18
		var border_a: float = 0.55
		var text_a: float = 0.75
		if is_active:
			bg_a = 0.30
			border_a = 0.95
			text_a = 1.0

		draw_rect(rect, Color(1, 1, 1, bg_a), true)
		draw_rect(rect, Color(1, 1, 1, border_a), false, 2.0)

		var text: String = String(labels.get(mode, str(mode)))

		var font: Font = get_theme_default_font()
		var font_size: int = get_theme_default_font_size()
		var pos: Vector2 = rect.position + Vector2(12.0, card_size.y * 0.65)

		draw_string(
			font,
			pos,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color(1, 1, 1, text_a)
		)
