extends CharacterBody2D

@export var velocidade: float = 130.0
@export var vida: int = 3
@export var recarga_gelo: float = 3.0
@export var alcance_golpe: float = 56.0
@export_range(30.0, 180.0) var abertura_golpe: float = 115.0
@export var intervalo_golpe: float = 0.4
@export var cena_projetil_gelo: PackedScene

var invencivel := false
var pode_atacar := true
var ultima_direcao := Vector2.DOWN
var tempo_restante_gelo := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var ataque: Area2D = $Ataque
@onready var golpe: ColorRect = $Ataque/Golpe
const EFEITO_GOLPE = preload("res://scripts/efeito_golpe.gd")

func _process(delta: float) -> void:
	tempo_restante_gelo = maxf(0.0, tempo_restante_gelo - delta)
	if not invencivel and hurtbox.has_overlapping_bodies():
		levar_dano()
	if pode_atacar and Input.is_action_just_pressed("atacar"):
		atacar()
	if Input.is_action_just_pressed("poder_gelo") and tempo_restante_gelo <= 0.0:
		lancar_gelo()

func _physics_process(_delta: float) -> void:
	var direcao := Input.get_vector("left", "right", "up", "down")
	velocity = direcao * velocidade
	move_and_slide()
	if direcao == Vector2.ZERO:
		anim.stop()
		return
	ultima_direcao = direcao.normalized()
	if abs(direcao.x) > abs(direcao.y):
		anim.play("direita" if direcao.x > 0 else "esquerda")
	else:
		anim.play("baixo" if direcao.y > 0 else "cima")

func levar_dano() -> void:
	if invencivel:
		return
	vida -= 1
	if vida <= 0:
		get_tree().current_scene.perder()
		return
	invencivel = true
	modulate.a = 0.4
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	modulate.a = 1.0
	invencivel = false

func atacar() -> void:
	pode_atacar = false
	# O quadrado antigo permanece na cena, mas nunca e exibido.
	golpe.hide()

	# Visual acompanha a direcao do ultimo movimento (inclusive parado).
	var visual: Node2D = EFEITO_GOLPE.new()
	visual.set("direcao", ultima_direcao)
	visual.set("raio", alcance_golpe)
	add_child(visual)

	# Dano em cone: apenas inimigos a frente, dentro do alcance.
	var frente := ultima_direcao.normalized()
	var angulo_minimo := cos(deg_to_rad(abertura_golpe * 0.5))
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not is_instance_valid(inimigo) or inimigo.is_queued_for_deletion():
			continue
		if not inimigo is Node2D or not inimigo.has_method("levar_golpe"):
			continue
		var deslocamento: Vector2 = inimigo.global_position - global_position
		var distancia := deslocamento.length()
		if distancia <= alcance_golpe and (distancia < 8.0 or frente.dot(deslocamento.normalized()) >= angulo_minimo):
			inimigo.levar_golpe()

	await get_tree().create_timer(maxf(0.1, intervalo_golpe)).timeout
	if not is_inside_tree():
		return
	pode_atacar = true

func lancar_gelo() -> void:
	if cena_projetil_gelo == null:
		push_warning("Defina cena_projetil_gelo no Inspector do Jogador.")
		return
	var projetil = cena_projetil_gelo.instantiate()
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = global_position + ultima_direcao * 24.0
	projetil.direcao = ultima_direcao
	tempo_restante_gelo = maxf(0.01, recarga_gelo)
