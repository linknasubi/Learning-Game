extends RefCounted
class_name Iso

# Projeção 2:1 (padrão)
static func world_to_iso(p: Vector2) -> Vector2:
	return Vector2(p.x - p.y, (p.x + p.y) * 0.5)

static func iso_to_world(p: Vector2) -> Vector2:
	# inversa da 2:1
	return Vector2((p.x + 2.0 * p.y) * 0.5, (2.0 * p.y - p.x) * 0.5)
