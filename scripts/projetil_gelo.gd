extends Area2D

@export var velocidade: float = 360.0
@export var alcance: float = 360.0
@export var raio: float = 12.0

var direcao := Vector2.DOWN
var distancia := 0.0
var tempo := 0.0
var ja_acertou := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0xFFFFFFFF
	monitoring = true
	var colisao := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = raio
	colisao.shape = circulo
	add_child(colisao)
	body_entered.connect(_ao_atingir)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if ja_acertou:
		return
	var deslocamento := velocidade * delta
	global_position += direcao.normalized() * deslocamento
	distancia += deslocamento
	tempo += delta
	queue_redraw()
	if distancia >= alcance:
		queue_free()

func _draw() -> void:
	# Efeito provisório em pixels/cores; pode trocar por Sprite2D futuramente.
	var pulso := 1.0 + 0.12 * sin(tempo * 18.0)
	draw_circle(Vector2.ZERO, raio * 1.6 * pulso, Color(0.2, 0.8, 1.0, 0.18))
	draw_circle(Vector2.ZERO, raio * pulso, Color(0.1, 0.65, 1.0, 0.65))
	draw_circle(Vector2.ZERO, raio * 0.65, Color(0.65, 0.95, 1.0, 0.95))
	draw_circle(Vector2(-3, -3), raio * 0.25, Color.WHITE)

func _ao_atingir(corpo: Node2D) -> void:
	if ja_acertou or not corpo.is_in_group("inimigos"):
		return
	if corpo.has_method("levar_golpe"):
		ja_acertou = true
		corpo.levar_golpe()
		queue_free()
