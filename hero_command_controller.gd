extends Node
class_name HeroCommandController

# Pode ser um herói específico...
@export var hero_path: NodePath
@onready var hero: Node2D = get_node_or_null(hero_path)


func command_move_to(world_pos: Vector2) -> void:
	if not is_instance_valid(hero):
		return
	if hero.has_method("set_move_target"):
		hero.call("set_move_target", world_pos)
