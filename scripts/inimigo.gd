extends CharacterBody2D

@export var velocidade: float = 65.0
@export var vida: int = 1
@export var forca_recuo: float = 230.0
@export var duracao_recuo: float = 0.20
@export_range(0.0, 0.6) var bonus_velocidade_nevasca: float = 0.16

@onready var agente: NavigationAgent2D = $NavigationAgent2D
const EFEITO_IMPACTO = preload("res://scripts/efeito_impacto.gd")

var velocidade_recuo := Vector2.ZERO
var tempo_recuo := 0.0
var tempo_flash := 0.0
var cor_original := Color.WHITE

func _ready() -> void:
	add_to_group("inimigos")
	cor_original = modulate

func _physics_process(delta: float) -> void:
	if tempo_flash > 0.0:
		tempo_flash -= delta
		if tempo_flash <= 0.0:
			modulate = cor_original
	if tempo_recuo > 0.0:
		tempo_recuo -= delta
		velocity = velocidade_recuo * maxf(0.0, tempo_recuo / maxf(0.01, duracao_recuo))
		move_and_slide()
		return
	var jogador := get_tree().get_first_node_in_group("player") as Node2D
	if jogador == null:
		velocity = Vector2.ZERO
		return
	agente.target_position = jogador.global_position
	if agente.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var proximo := agente.get_next_path_position()
	var direcao := global_position.direction_to(proximo)
	if direcao != Vector2.ZERO:
		rotation = direcao.angle()
	# Na tempestade as focas cacam um pouco mais depressa.
	var cenario := get_tree().current_scene
	var intensidade := 0.0
	if cenario != null and cenario.has_method("intensidade_da_nevasca"):
		intensidade = float(cenario.intensidade_da_nevasca())
	velocity = direcao * velocidade * (1.0 + bonus_velocidade_nevasca * intensidade)
	move_and_slide()

func levar_golpe() -> void:
	var jogador := get_tree().get_first_node_in_group("player") as Node2D
	var empurrao := Vector2.RIGHT.rotated(rotation)
	if jogador != null:
		empurrao = jogador.global_position.direction_to(global_position)
	if empurrao.length_squared() < 0.01:
		empurrao = Vector2.RIGHT
	var impacto: Node2D = EFEITO_IMPACTO.new()
	impacto.set("direcao", empurrao)
	get_tree().current_scene.add_child(impacto)
	impacto.global_position = global_position
	vida -= 1
	if vida <= 0:
		get_tree().current_scene.inimigo_morreu(self)
		queue_free()
		return
	if tempo_flash <= 0.0:
		cor_original = modulate
	velocidade_recuo = empurrao * forca_recuo
	tempo_recuo = duracao_recuo
	modulate = cor_original.lerp(Color(0.65, 0.94, 1.0, cor_original.a), 0.65)
	tempo_flash = 0.11
