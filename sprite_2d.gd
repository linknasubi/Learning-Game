extends Sprite2D

@export var bob_height := 2.5       # quanto sobe/desce (pixels)
@export var bob_speed := 10.0       # velocidade da oscilação
@export var move_threshold := 8.0   # mínimo de velocidade pra considerar "andando"
@export var smooth := 12.0          # suavização do efeito

var _base_pos := Vector2.ZERO
var _t := 0.0
var _bob_amount := 0.0

func _ready() -> void:
	_base_pos = position

func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if body == null:
		return

	var moving := body.velocity.length() > move_threshold

	# alvo do "quanto aplicar" (0 parado, 1 andando)
	var target_amount := 1.0 if moving else 0.0
	_bob_amount = lerpf(_bob_amount, target_amount, smooth * delta)

	# só avança o tempo quando estiver andando (ou quase andando)
	if _bob_amount > 0.01:
		_t += delta * bob_speed

	# oscilação vertical suave (sobe e desce)
	var y_off := -sin(_t) * bob_height * _bob_amount

	position = _base_pos + Vector2(0.0, y_off)
