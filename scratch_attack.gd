extends Node
class_name EnemyScratchAttack

@export var stats: Stats
@export var owner_body: CharacterBody2D
@export var target: Node2D
@export var attack_area: Area2D

@export var cooldown: float = 0.9
@export var range_px: float = 36.0
@export var cone_deg: float = 25.0

var _t: float = 0.0

func _ready() -> void:
	# auto-wire básico (se você esquecer de arrastar no Inspector)
	if target == null:
		target = get_tree().get_first_node_in_group("heroes") as Node2D
		print(target)
	if owner_body == null:
		owner_body = get_parent() as CharacterBody2D
	if attack_area == null and owner_body != null and owner_body.has_node("ScratchArea"):
		attack_area = owner_body.get_node("ScratchArea") as Area2D

	# garante que o raio do círculo acompanha range_px (opcional)
	if attack_area != null and attack_area.has_node("CollisionShape2D"):
		var cs := attack_area.get_node("CollisionShape2D") as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			(cs.shape as CircleShape2D).radius = range_px

func _process(delta: float) -> void:
	if owner_body == null or attack_area == null or stats == null or target == null:
		return
	_t -= delta
	if _t > 0.0:
		return

	# só tenta arranhar se o target está perto
	var dist: float = owner_body.global_position.distance_to(target.global_position)
	if dist > range_px:
		return
	print('no range')
	_t = cooldown
	_do_scratch()

func _do_scratch() -> void:
	var forward: Vector2 = (target.global_position - owner_body.global_position)
	if forward.length() < 0.001:
		return
	forward = forward.normalized()

	# ✅ pega o VFX de forma segura + garante que existe mesmo
	var vfx := owner_body.get_node_or_null("ScratchVFX") as ScratchVFX
	if vfx == null:
		print("ScratchVFX NÃO encontrado em: ", owner_body.name, " filhos: ", owner_body.get_children())
	else:
		# ✅ garante que fica acima
		vfx.z_as_relative = false
		vfx.z_index = 999
		vfx.position = Vector2.ZERO
		vfx.play(forward)


	# filtro do cone: metade do ângulo (25° total => 12.5° pra cada lado)
	var half_rad: float = deg_to_rad(cone_deg * 0.5)
	var min_dot: float = cos(half_rad)

	# pega todos dentro do alcance circular e filtra pelo cone
	var bodies := attack_area.get_overlapping_bodies()
	for b in bodies:
		if not (b is Node2D):
			continue
		if not b.is_in_group("heroes"):
			continue

		var to_b: Vector2 = ((b as Node2D).global_position - owner_body.global_position)
		if to_b.length() < 0.001:
			continue
		to_b = to_b.normalized()

		var dot: float = forward.dot(to_b)
		if dot < min_dot:
			continue

		# dano
		if b.has_node("Health"):
			var h: Health = b.get_node("Health")
			h.take_damage(stats.attack, owner_body)

		break
