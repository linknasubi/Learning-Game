# res://components/stats.gd
extends Resource
class_name Stats

@export var max_hp: int = 10
@export var attack: int = 1
@export var move_speed: float = 200.0
@export var attack_speed: float = 1.0  # ataques por segundo (>= 0.1 recomendado)
@export var number_of_attacks: int = 1  # quantos ataques/projéteis por ação

# só inimigos usam isso (quanto XP dão ao morrer)
@export var xp_value: int = 1
