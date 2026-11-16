extends CharacterBody2D

@export var velocidade: float = 65.0
@export var vida: int = 1
@onready var agente: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	add_to_group("inimigos")

func _physics_process(_delta: float) -> void:
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
	velocity = direcao * velocidade
	move_and_slide()

func levar_golpe() -> void:
	vida -= 1
	if vida <= 0:
		get_tree().current_scene.inimigo_morreu(self)
		queue_free()
