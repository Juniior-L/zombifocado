extends Node2D

@export var cena_inimigo: PackedScene
@export var cena_item: PackedScene
@export var max_inimigos: int = 15
@export var objetivo_itens: int = 20

var abates := 0
var coletados := 0
var partida_encerrada := false

@onready var horda: Timer = $Horda
@onready var relogio: Timer = $Relogio
@onready var jogador = $Jogador
@onready var texto_vida: Label = $HUD/Vida
@onready var texto_tempo: Label = $HUD/Tempo

func _process(_delta: float) -> void:
	texto_vida.text = "Vida: %d Abates: %d" % [jogador.vida, abates]
	texto_tempo.text = "Itens: %d / %d" % [coletados, objetivo_itens]

func inimigo_morreu(_inimigo: Node2D) -> void:
	if not partida_encerrada:
		abates += 1

func _on_horda_timeout() -> void:
	if partida_encerrada or cena_inimigo == null:
		return
	if get_tree().get_nodes_in_group("inimigos").size() >= max_inimigos:
		return
	var pontos = $Nascedouros.get_children()
	if pontos.is_empty():
		return
	var inimigo = cena_inimigo.instantiate()
	inimigo.global_position = pontos.pick_random().global_position
	add_child(inimigo)
	horda.wait_time = max(0.5, horda.wait_time * 0.95)

func _on_relogio_timeout() -> void:
	# O objetivo agora e coletar todos os itens; o relogio nao gera vitoria automatica.
	pass

func vencer() -> void:
	if partida_encerrada:
		return
	partida_encerrada = true
	get_tree().change_scene_to_file.call_deferred("res://scenes/vitoria.tscn")

func perder() -> void:
	if partida_encerrada:
		return
	partida_encerrada = true
	get_tree().change_scene_to_file.call_deferred("res://scenes/derrota.tscn")

func _on_itens_timeout() -> void:
	if partida_encerrada or coletados >= objetivo_itens or cena_item == null:
		return
	var pontos = $Pontos.get_children()
	if pontos.is_empty():
		return
	var item = cena_item.instantiate()
	item.global_position = pontos.pick_random().global_position
	add_child(item)

func coletou() -> void:
	if partida_encerrada:
		return
	coletados += 1
	if coletados >= objetivo_itens:
		vencer()
