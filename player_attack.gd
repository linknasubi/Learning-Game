extends Node
class_name BowAttack

@export var arrow_scene: PackedScene = preload("res://Arrow.tscn")
@export var stats: Stats
@export var owner_body: Node2D
@export var cooldown: float = 0.35
@export var range_px: float = 900.0
@export var attack_range: float = 380.0
@export var stop_attack_range: float = 400.0
@onready var sfx_bow: AudioStreamPlayer2D = get_node_or_null("SFXBow") as AudioStreamPlayer2D
@export var bow_sfx: AudioStream = preload("res://bow_sound.mp3")

var _t: float = 0.0
var _in_attack_range: bool = false


func _ready() -> void:
	if is_instance_valid(sfx_bow) and sfx_bow.stream == null:
		sfx_bow.stream = bow_sfx



func _process(delta: float) -> void:
	if owner_body == null or stats == null:
		return

	# 1) busca o alvo (já limitado ao "alcance de interesse")
	var target := _find_nearest_enemy()
	if target == null:
		_in_attack_range = false
		return

	# 2) histerese do range (entra <= attack_range, sai > stop_attack_range)
	var dist: float = owner_body.global_position.distance_to(target.global_position)

	if _in_attack_range:
		if dist > stop_attack_range:
			_in_attack_range = false
	else:
		if dist <= attack_range:
			_in_attack_range = true

	# 3) se não está no range, não atira e NÃO consome cooldown
	if not _in_attack_range:
		return

	# 4) cooldown só conta quando vai atirar
	_t -= delta
	if _t > 0.0:
		return

	var atk_speed: float = maxf(0.1, stats.attack_speed)
	_t = maxf(0.02, 1.0 / atk_speed)

	var targets := _pick_targets_in_range(stats.number_of_attacks)
	if targets.is_empty():
		return
	if is_instance_valid(sfx_bow):
		# reinicia caso já esteja tocando (tiros rápidos)
		sfx_bow.stop()
		sfx_bow.play()

	_shoot_at_targets(targets)


	_shoot_at_targets(targets)

func _shoot_at_targets(targets: Array[Node2D]) -> void:
	var origin: Vector2 = owner_body.global_position

	for t in targets:
		if not is_instance_valid(t) or t.is_queued_for_deletion():
			continue

		var dir: Vector2 = (t.global_position - origin)
		if dir.length() <= 0.001:
			continue
		dir = dir.normalized()

		var arrow := arrow_scene.instantiate() as Area2D
		get_tree().current_scene.add_child(arrow)

		arrow.global_position = origin
		arrow.shooter = owner_body
		arrow.damage = stats.attack

		arrow.dir = dir
		arrow.rotation = arrow.dir.angle()

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null

	var search: float = minf(range_px, stop_attack_range)
	var best_d2: float = search * search

	for n in enemies:
		if n is Node2D:
			var d2: float = owner_body.global_position.distance_squared_to(n.global_position)
			if d2 < best_d2:
				best_d2 = d2
				best = n

	return best
	
func _pick_targets_in_range(count: int) -> Array[Node2D]:
	var n := maxi(1, count)

	var candidates: Array[Node2D] = []
	var enemies := get_tree().get_nodes_in_group("enemies")

	var origin := owner_body.global_position
	var search := minf(range_px, stop_attack_range)
	var search2 := search * search

	for e in enemies:
		if not (e is Node2D):
			continue
		var en := e as Node2D
		if not is_instance_valid(en) or en.is_queued_for_deletion():
			continue

		var d2 := origin.distance_squared_to(en.global_position)
		if d2 <= search2:
			candidates.append(en)

	# ordena por mais perto
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)

	# pega até n alvos distintos
	if candidates.size() > n:
		candidates.resize(n)

	return candidates
