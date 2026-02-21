extends Node
class_name ControlManager

signal mode_changed(mode: int)

enum Mode { SPAWN = 1, COMMAND = 2 }

@export var mode: Mode = Mode.SPAWN
@export var spawner_path: NodePath
@export var hero_path: NodePath
@export var hero_command_path: NodePath
@export var hud_cards_path: NodePath

@onready var hero_command: HeroCommandController = get_node_or_null(hero_command_path)
var hud_cards: ModeCardsHUD


@onready var spawner: Spawner = get_node_or_null(spawner_path)
@onready var hero: Node2D = get_node_or_null(hero_path)


func _ready() -> void:
	var found := get_tree().get_first_node_in_group("mode_hud")
	if found is ModeCardsHUD:
		hud_cards = found
	emit_signal("mode_changed", int(mode))
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	# trocar modo (1/2) - depois você amplia pra 3/4
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_set_mode(Mode.SPAWN)
			return
		if event.keycode == KEY_2:
			_set_mode(Mode.COMMAND)
			return

	# clique esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world := get_viewport().get_camera_2d().get_global_mouse_position()

		if mode == Mode.SPAWN:
			if event.pressed:
				if is_instance_valid(spawner):
					spawner.begin_charge(mouse_world)
			else:
				if is_instance_valid(spawner):
					spawner.release_charge()

		elif mode == Mode.COMMAND:
			if event.pressed:
				if is_instance_valid(hero_command):
					hero_command.command_move_to(mouse_world)


func _set_mode(new_mode: Mode) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	emit_signal("mode_changed", int(mode))
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(hud_cards):
		hud_cards.active_mode = int(mode)
