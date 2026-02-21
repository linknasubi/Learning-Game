extends CharacterBody2D

@export var speed := 120.0
var target: Node2D
@onready var health: Health = $Health
signal killed(killer: Node, xp_value: int)
@onready var spr: CanvasItem = $Sprite2D # ou AnimatedSprite2D
@export var knockback_strength := 140.0
@export var stagger_time := 0.08
@export var chase_range := 220.0          # começa a perseguir se estiver <= isso
@export var stop_chase_range := 260.0     # opcional: evita ficar liga/desliga na borda
var _is_chasing := false

var _stagger_left := 0.0
var _knock_vel := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health.hp_changed.connect(_on_hp_changed)
	health.damaged.connect(_on_damaged)


func _on_damaged(_amount: int, attacker: Node) -> void:
	_hit_flash()

	if attacker is Node2D:
		apply_hit((attacker as Node2D).global_position)

func _on_hp_changed(_cur: int, _max: int) -> void:
	_hit_flash()
	
	
func _hit_flash() -> void:
	if spr == null:
		return
	spr.modulate = Color(2,2,2,1) # "branco"
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(spr):
		spr.modulate = Color(1,1,1,1)


func apply_hit(attacker_pos: Vector2) -> void:
	var dir: Vector2 = (global_position - attacker_pos)
	if dir.length() > 0.001:
		dir = dir.normalized()
	_knock_vel = dir * knockback_strength
	_stagger_left = stagger_time


func _physics_process(_delta: float) -> void:
	
	if _stagger_left > 0.0:
		_stagger_left -= _delta
		velocity = _knock_vel
		move_and_slide()
		_knock_vel = _knock_vel.lerp(Vector2.ZERO, 12.0 * _delta)
		return


	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := (target.global_position - global_position)
	var dist := to_target.length()

	# decide se deve perseguir (com histerese opcional)
	if _is_chasing:
		if dist > stop_chase_range:
			_is_chasing = false
	else:
		if dist <= chase_range:
			_is_chasing = true

	if _is_chasing and dist > 1.0:
		velocity = to_target / dist * speed  # normalizado sem recalcular
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

	
func _on_died(killer: Node) -> void:
	set_physics_process(false)

	# 2) opcional: desliga colisões pra não atrapalhar
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# 3) opcional: toque animação/efeito
	# if has_node("AnimatedSprite2D"): $AnimatedSprite2D.play("die")

	emit_signal("killed", killer, health.stats.xp_value)
	queue_free()
