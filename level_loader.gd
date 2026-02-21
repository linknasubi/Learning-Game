extends Node
class_name LevelLoader

@export var level_root_path: NodePath = ^"../LevelRoot"
@export var agent_path: NodePath = ^"../Agent"
@export var player_path: NodePath
@export var player_spawn_path: NodePath = NodePath("Markers/PlayerSpawn")

var _player: Node2D

@export var initial_level: PackedScene  # arrasta Level_Bridge.tscn aqui

var _level_root: Node2D
var _agent: Node2D
var _current_level: Node = null

func _ready() -> void:
	_level_root = get_node_or_null(level_root_path) as Node2D
	_agent = get_node_or_null(agent_path) as Node2D
	_player = get_node_or_null(player_path) as Node2D

	if _level_root == null:
		push_error("LevelLoader: LevelRoot não encontrado.")
		return
	if _agent == null:
		push_error("LevelLoader: Agent não encontrado.")
		return

	if initial_level != null:
		load_level(initial_level)

func _apply_player_spawn() -> void:
	if _player == null or not is_instance_valid(_player):
		push_error("LevelLoader: player_path inválido.")
		return

	if _current_level == null or not is_instance_valid(_current_level):
		return

	# garante que os transforms/global_position já foram atualizados
	await get_tree().process_frame

	var spawn := _current_level.get_node_or_null(player_spawn_path) as Marker2D
	if spawn == null:
		push_error("LevelLoader: não achei PlayerSpawn em: " + String(player_spawn_path))
		return

	_player.global_position = spawn.global_position


func load_level(scene: PackedScene) -> void:
	# remove fase anterior
	if _current_level != null and is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null

	# instancia a nova fase
	_current_level = scene.instantiate()
	_level_root.add_child(_current_level)
	
	_current_level = scene.instantiate()
	_level_root.add_child(_current_level)

	call_deferred("_apply_player_spawn")


	# acha spawn
	var spawn := _current_level.get_node_or_null("Markers/PlayerSpawn") as Marker2D
	if spawn == null:
		push_error("LevelLoader: Markers/PlayerSpawn não existe na fase.")
		return

	# posiciona o player
	_agent.global_position = spawn.global_position
