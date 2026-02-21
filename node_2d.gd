extends Node2D

@export var enemy_scene: PackedScene = preload("res://Enemy.tscn")
@onready var floor: Sprite2D = $Agent/Camera2D/Floor
@onready var agent: CharacterBody2D = $Agent
@export var floating_text_scene: PackedScene = preload("res://FloatingText.tscn")
@export var ui_path: NodePath
@onready var ui_layer: CanvasLayer = get_node_or_null(ui_path) as CanvasLayer
@onready var leveling: Leveling = get_node_or_null("Agent/Leveling") as Leveling
var _player_dead := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_instance_valid(leveling):
		leveling.leveled_up.connect(func(_level: int) -> void:
			_spawn_levelup_text()
		)

	# se o Agent emite "died", marcamos pra não acessar mais nada dele
	if is_instance_valid(agent) and agent.has_signal("died"):
		agent.connect("died", Callable(self, "_on_player_died"))

func _on_player_died(_killer: Node) -> void:
	_player_dead = true
	agent = null
	floor = null
	# opcional: para o _process desse controller
	set_process(false)


func _spawn_levelup_text() -> void:
	if _player_dead or not is_instance_valid(agent):
		return

	if floating_text_scene == null:
		return

	var txt := floating_text_scene.instantiate() as FloatingText
	if txt == null:
		return

	# adiciona no UI se quiser “sempre na tela”, ou no World se quiser “no mundo”
	# eu recomendo UI (CanvasLayer) pra ficar consistente com câmera
	if is_instance_valid(ui_layer):
		ui_layer.add_child(txt)
	else:
		add_child(txt) # fallback: adiciona no World


	# posição na cabeça: pega posição do Agent e aplica offset
	var head_pos: Vector2 = agent.global_position + Vector2(0, -36)

	txt.play(head_pos, "LEVEL UP!")


func wire_enemy(enemy: Node) -> void:
	var h: Health = enemy.get_node("Health") as Health
	h.died.connect(func(killer: Node) -> void:
		# se o player já morreu (ou foi liberado), não tenta acessar nada dele
		if _player_dead or not is_instance_valid(agent) or not is_instance_valid(leveling):
			return

		if killer != agent:
			return

		var st: Stats = h.stats
		if st != null:
			leveling.add_xp(st.xp_value)

		enemy.queue_free()
	)

func _process(_delta: float) -> void:
	if agent == null or not is_instance_valid(agent) or agent.is_queued_for_deletion():
		return
	if floor == null or not is_instance_valid(floor) or floor.is_queued_for_deletion():
		return

	floor.region_rect.position = agent.global_position
