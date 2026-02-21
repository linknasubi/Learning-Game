# res://components/leveling.gd
extends Node
class_name Leveling

# Quando sobe de nível
signal leveled_up(level: int)

# Para UI/XP bar
signal xp_changed(current: int, to_next: int)

@export var stats: Stats
@export var health: Health

var level: int = 1
var xp: int = 0

func _ready() -> void:
	# auto-wire do Health (se não setar no Inspector)
	if health == null:
		var p: Node = get_parent()
		if p != null and p.has_node("Health"):
			health = p.get_node("Health") as Health

	# emite estado inicial (útil pra XP bar aparecer certo no start)
	emit_signal("xp_changed", xp, xp_to_next())


func xp_to_next() -> int:
	# simples e escalável (curva linear)
	return 5 + (level - 1) * 3


func add_xp(amount: int) -> void:
	# ---------- guards ----------
	if amount <= 0:
		return

	if health == null or not is_instance_valid(health) or health.is_queued_for_deletion():
		return

	# se você tiver hp dentro do Health
	if health.hp <= 0:
		return

	# ---------- acumula ----------
	xp += amount

	# evita chamar xp_to_next() repetidamente do jeito "errado"
	var need: int = xp_to_next()

	while xp >= need:
		xp -= need
		level_up()
		need = xp_to_next() # após subir de nível, recalcula o próximo

	emit_signal("xp_changed", xp, need)


func level_up() -> void:
	level += 1

	# ============================================================
	# AQUI ocorre o aumento dos stats conforme upa
	# ============================================================
	if stats != null:
		# -----------------------------
		# crescimento multiplicativo
		# -----------------------------

		# HP: cresce em % e mantém int (arredondando pra cima)
		stats.max_hp = maxi(stats.max_hp + 1, int(ceil(float(stats.max_hp) * 1.08)))  # +8%/lvl

		# Attack: cresce em % e mantém int (garante subir no mínimo +1)
		var new_attack: int = int(ceil(float(stats.attack) * 1.10))                  # +10%/lvl
		stats.attack = maxi(stats.attack + 1, new_attack)

		# Move speed: cresce em % (float)
		stats.move_speed = stats.move_speed * 1.1                                   # +10%/lvl

		# Attack speed: cresce em % e tem teto (ex: 5 atk/s)
		stats.attack_speed = minf(5.0, stats.attack_speed * 1.06)                    # +6%/lvl
		
			# Number of attacks: +12%/lvl (int) com ceil
	# (cresce devagar e “pinga” +1 de tempos em tempos)
	var new_n: int = int(ceil(float(stats.number_of_attacks) * 1.3))
	stats.number_of_attacks = maxi(1, new_n)

	emit_signal("leveled_up", level)
