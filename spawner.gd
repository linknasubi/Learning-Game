extends Node2D
class_name Spawner

@export var enemy_scene: PackedScene
@export var agent: Node2D

@export var max_charge_time := 2.0
@export var min_radius := 20.0
@export var max_radius := 220.0
@export var min_enemies := 1
@export var max_enemies := 20
@onready var charge_sfx: AudioStreamPlayer2D = $ChargeSFX
@onready var release_sfx: AudioStreamPlayer2D = $ReleaseSFX

@export var charge_pitch_min := 0.85
@export var charge_pitch_max := 1.35
@export var charge_vol_min_db := -18.0
@export var charge_vol_max_db := -6.0

var is_charging := false
var charge_center: Vector2
var charge_time := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func begin_charge(world_pos: Vector2) -> void:
	is_charging = true
	charge_time = 0.0
	charge_center = world_pos

	if charge_sfx != null:
		charge_sfx.pitch_scale = charge_pitch_min
		charge_sfx.volume_db = charge_vol_min_db
		if not charge_sfx.playing:
			charge_sfx.play()

	queue_redraw()


func release_charge() -> void:
	if not is_charging:
		return

	_commit_spawn()

	# SFX: para o loop e toca o release
	if charge_sfx != null and charge_sfx.playing:
		charge_sfx.stop()

	if release_sfx != null:
		release_sfx.pitch_scale = lerpf(
			0.95, 1.15,
			clamp(charge_time / max_charge_time, 0.0, 1.0)
		)
		release_sfx.play()

	is_charging = false
	queue_redraw()

func _process(delta: float) -> void:
	if is_charging:
		charge_time = min(charge_time + delta, max_charge_time)
		var t: float = clamp(charge_time / max_charge_time, 0.0, 1.0)

		if charge_sfx != null and charge_sfx.playing:
			charge_sfx.pitch_scale = lerpf(charge_pitch_min, charge_pitch_max, t)
			charge_sfx.volume_db = lerpf(charge_vol_min_db, charge_vol_max_db, t)

		queue_redraw()

func _draw() -> void:
	if not is_charging:
		return
	
	var t: float = clamp(charge_time / max_charge_time, 0.0, 1.0)
	var radius: float = lerpf(min_radius, max_radius, t)
	var center_local: Vector2 = to_local(charge_center)
	
	var marks: int = 8
	for i in range(marks):
		var ang: float = (TAU * float(i) / float(marks)) + (t * 0.6)
		var a: Vector2 = Vector2(cos(ang), sin(ang)) * (radius * 0.78)
		var b: Vector2 = Vector2(cos(ang), sin(ang)) * (radius * 0.92)
		draw_line(center_local + a, center_local + b, Color(1,1,1,0.55), 2.0)

	draw_circle(center_local, radius, Color(1, 1, 1, 0.08))
	draw_arc(center_local, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.7), 2.0)
	draw_arc(center_local, radius * 0.55, 0.0, TAU, 48, Color(1,1,1,0.25), 1.0)

func _commit_spawn() -> void:
	if enemy_scene == null or agent == null:
		return

	var t: float = clamp(charge_time / max_charge_time, 0.0, 1.0)
	var radius: float = lerp(min_radius, max_radius, t)
	var count: int = int(round(lerp(float(min_enemies), float(max_enemies), t)))

	for i in range(count):
		var ang: float = rng.randf_range(0.0, TAU)
		var r: float = sqrt(rng.randf()) * radius
		var pos: Vector2 = charge_center + Vector2(cos(ang), sin(ang)) * r
		print(pos)
		_spawn_enemy(pos)


func _spawn_enemy(world_pos: Vector2) -> void:
	var e := enemy_scene.instantiate() as CharacterBody2D
	if e == null:
		push_error("Enemy.tscn não tem root CharacterBody2D (cast falhou).")
		return

	get_tree().current_scene.add_child(e)
	e.global_position = world_pos
	e.target = agent

	e.killed.connect(func(killer: Node, xp_value: int):
		if killer == agent:
			(agent.get_node("Leveling") as Leveling).add_xp(xp_value)
	)

	
