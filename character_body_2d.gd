extends CharacterBody2D
# Herói: IA de fuga + modo de comando (vai ao alvo desviando de inimigos)
# Integra Stats/Leveling (move_speed vindo do Resource Stats)

# ============================================================
# 1) CONFIGURAÇÃO (Inspector)
# ============================================================

# --- Stats / Progressão ---
@export var stats: Stats
@onready var leveling: Leveling = get_node_or_null("Leveling") as Leveling

# --- Movimento base ---
@export var steering: float = 10.0  # suaviza mudança brusca de direção/velocidade

# --- IA: percepção e evasão ---
@export var threat_radius: float = 420.0   # raio para considerar inimigos
@export var ideal_distance: float = 260.0  # distância "confortável" pro peso de repulsão

# --- IA: comando (ir ao ponto) ---
@export var arrive_dist: float = 18.0     # distância para considerar "cheguei"
@export var goal_weight: float = 1.0      # força de ir ao objetivo
@export var avoid_weight: float = 1.35    # força de evitar inimigos

# --- Ruído leve (para não ficar tremendo/parado) ---
@export var wander_strength: float = 0.08

@export var obstacle_avoid_weight: float = 1.25
@export var obstacle_lookahead: float = 46.0
@export var obstacle_side_lookahead: float = 28.0
@export var obstacle_mask: int = 1   # ajuste no Inspector p/ camada de paredes/obstáculos


# ============================================================
# 2) NODES / SINAIS
# ============================================================

signal died(killer: Node)

@onready var health: Health = $Health
@onready var spr: CanvasItem = $Sprite2D

# ============================================================
# 3) ESTADO INTERNO
# ============================================================

# comando do ControlManager (target no mundo)
var has_target: bool = false
var move_target: Vector2 = Vector2.ZERO

# velocidade efetiva (vem de stats.move_speed)
var _move_speed: float = 220.0

# wander
var _wander_phase: float = 0.0
var _ray_query := PhysicsRayQueryParameters2D.new()


# ============================================================
# 4) LIFECYCLE
# ============================================================

func _ready() -> void:
	# --- Stats: evita compartilhar o mesmo Resource entre instâncias ---
	# (se você usa um .tres no Inspector, sem duplicar todo mundo compartilha)
	if is_instance_valid(leveling):
		leveling.stats = stats

	var bow := get_node_or_null("PlayerAttack") as BowAttack
	if is_instance_valid(bow):
		bow.stats = stats
		bow.owner_body = self

	_refresh_from_stats()

	# --- Leveling: garante que usa o MESMO stats do Agent ---
	if is_instance_valid(leveling):
		leveling.stats = stats
		leveling.leveled_up.connect(func(_lvl: int) -> void:
			_refresh_from_stats()
		)

	# --- Health signals ---
	health.died.connect(_on_died)
	health.hp_changed.connect(_on_hp_changed)


func _refresh_from_stats() -> void:
	# Recarrega valores “runtime” a partir do Resource
	if stats != null:
		_move_speed = stats.move_speed


# ============================================================
# 5) FEEDBACK DE DANO / MORTE
# ============================================================

func _on_hp_changed(_cur: int, _max: int) -> void:
	_hit_flash()


func _hit_flash() -> void:
	# flash branco rápido ao tomar dano (feedback simples)
	if spr == null:
		return

	spr.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.06).timeout

	if is_instance_valid(spr):
		spr.modulate = Color(1, 1, 1, 1)


func _on_died(killer: Node) -> void:
	# Para a IA e remove colisões pra não empurrar mais nada
	set_physics_process(false)
	velocity = Vector2.ZERO
	has_target = false

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	emit_signal("died", killer)
	queue_free()


# ============================================================
# 6) API PÚBLICA (chamada pelo ControlManager)
# ============================================================

func set_move_target(pos: Vector2) -> void:
	move_target = pos
	has_target = true


func clear_move_target() -> void:
	has_target = false


# ============================================================
# 7) LOOP DE MOVIMENTO (Physics)
# ============================================================

func _obstacle_avoid(desired_dir: Vector2) -> Vector2:
	if desired_dir.length() <= 0.001:
		return Vector2.ZERO

	var origin := global_position
	var dir := desired_dir.normalized()

	var space := get_world_2d().direct_space_state

	# 1) ray principal (pra frente)
	_ray_query.from = origin
	_ray_query.to = origin + dir * obstacle_lookahead
	_ray_query.collision_mask = obstacle_mask
	_ray_query.exclude = [self]

	var hit := space.intersect_ray(_ray_query)
	if hit.is_empty():
		return Vector2.ZERO

	var normal: Vector2 = hit["normal"]

	# 2) tenta escolher o melhor lado (esquerda vs direita) fazendo dois rays laterais
	var left := Vector2(-dir.y, dir.x)
	var right := Vector2(dir.y, -dir.x)

	var left_score := _side_clearance(space, origin, dir, left)
	var right_score := _side_clearance(space, origin, dir, right)

	var side := left if left_score > right_score else right

	# 3) vetor tangente “escorrega” na parede e ainda empurra levemente pra fora (normal)
	var tangent := side
	var push := normal * 0.35

	return (tangent + push).normalized()


func _side_clearance(space: PhysicsDirectSpaceState2D, origin: Vector2, dir: Vector2, side: Vector2) -> float:
	# um ray que olha “pra frente e pro lado” pra ver qual lado é mais livre
	_ray_query.from = origin
	_ray_query.to = origin + (dir * obstacle_lookahead) + (side * obstacle_side_lookahead)
	_ray_query.collision_mask = obstacle_mask
	_ray_query.exclude = [self]

	var hit := space.intersect_ray(_ray_query)
	return 0.0 if not hit.is_empty() else 1.0



func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO

	# Se tem alvo, tenta ir até ele desviando de inimigos
	# Senão, usa fuga/kite padrão
	if has_target:
		dir = _compute_command_dir(delta)
	else:
		dir = _compute_flee_dir(delta)

	# normaliza/limita e aplica steering
	dir = dir.limit_length(1.0)
	velocity = velocity.lerp(dir * _move_speed, steering * delta)

	move_and_slide()


# ============================================================
# 8) IA: COMANDO (ir ao alvo + evitar inimigos)
# ============================================================

func _compute_command_dir(delta: float) -> Vector2:
	# 1) Checagem de chegada
	var to_goal: Vector2 = move_target - global_position
	var dist_goal: float = to_goal.length()

	if dist_goal <= arrive_dist:
		has_target = false
		return Vector2.ZERO

	var goal_dir: Vector2 = to_goal / maxf(0.001, dist_goal)  # normalizado seguro

	# 2) Evitar inimigos (repulsão)
	var avoid_dir: Vector2 = _compute_avoid_dir()

	# 3) Campo potencial: objetivo + evitar + leve wander
	var mixed: Vector2 = (goal_dir * goal_weight) \
		+ (avoid_dir * avoid_weight) \
		+ (_wander(delta) * 0.15)

	mixed += _obstacle_avoid(mixed) * obstacle_avoid_weight

	# 4) Se ficar muito pequeno (raro), segue objetivo direto
	if mixed.length() <= 0.001:
		return goal_dir

	return mixed.normalized()


func _compute_avoid_dir() -> Vector2:
	# Repulsão: soma vetores "away" ponderados pela distância
	var enemies := get_tree().get_nodes_in_group("enemies")
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0

	for n in enemies:
		if not (n is Node2D):
			continue
		var e: Node2D = n as Node2D

		var away: Vector2 = global_position - e.global_position
		var d: float = away.length()

		if d <= 0.001 or d > threat_radius:
			continue

		# peso forte quando perto; suave quando longe
		var x: float = maxf(0.05, d / ideal_distance)
		var w: float = 1.0 / (x * x)

		sum += away.normalized() * w
		count += 1

	if count == 0:
		return Vector2.ZERO

	return sum.normalized()


# ============================================================
# 9) IA: FUGA (kite) quando não há comando
# ============================================================

func _compute_flee_dir(delta: float) -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0

	for n in enemies:
		if not (n is Node2D):
			continue
		var e: Node2D = n as Node2D

		var to_me: Vector2 = global_position - e.global_position
		var d: float = to_me.length()

		if d <= 0.001 or d > threat_radius:
			continue

		var x: float = maxf(0.05, d / ideal_distance)
		var w: float = 1.0 / (x * x)

		sum += to_me.normalized() * w
		count += 1

	if count == 0:
		# sem ameaça: só um wander leve (ou você pode retornar Vector2.ZERO)
		return _wander(delta)

	var flee: Vector2 = sum.normalized()
	var mixed := (flee + _wander(delta) * 0.35)
	mixed += _obstacle_avoid(mixed) * obstacle_avoid_weight
	return mixed.normalized()



# ============================================================
# 10) WANDER (ruído leve)
# ============================================================

func _wander(delta: float) -> Vector2:
	_wander_phase += delta * 2.2
	return Vector2(cos(_wander_phase), sin(_wander_phase)) * wander_strength
