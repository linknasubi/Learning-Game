extends Sprite2D

@export var target_path: NodePath
@onready var target: Node2D = get_node_or_null(target_path)

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	# mantém o "tapete" centrado no alvo
	region_rect.position = target.global_position
