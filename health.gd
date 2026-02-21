# res://components/health.gd
extends Node
class_name Health

signal hp_changed(current: int, max: int)
signal died(killer: Node)
signal damaged(amount: int, attacker: Node)

@export var stats: Stats
var hp: int

func _ready() -> void:
	hp = stats.max_hp
	emit_signal("hp_changed", hp, stats.max_hp)

func take_damage(amount: int, killer: Node = null) -> void:
	if hp <= 0:
		return

	print("[DMG]", get_parent().name, " took ", amount, " hp:", hp, "->", max(0, hp - amount))

	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, stats.max_hp)

	emit_signal("damaged", amount, killer) # killer aqui é o atacante


	if hp == 0:
		print("[DIED]", get_parent().name, " killer=", killer)
		emit_signal("died", killer)
