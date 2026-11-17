extends Node2D

@export var cena_inimigo: PackedScene
@export var cena_item: PackedScene
@export var max_inimigos: int = 15
@export var objetivo_itens: int = 20
# Controle de coletaveis: valores ajustaveis no Inspector.
@export_range(1, 8, 1) var max_itens_ativos: int = 4
@export var distancia_minima_jogador_item: float = 110.0
@export var espera_reutilizar_ponto: float = 8.0
@export var itens_para_chefe: int = 15
@export var vida_chefe: int = 12
@export var velocidade_chefe: float = 88.0
# Progressao: a cada 5 suprimentos e necessario enfrentar as focas.
@export var itens_por_etapa: int = 5
@export var abates_por_etapa: int = 2
@export var exigir_derrotar_chefe: bool = true

var abates := 0
var coletados := 0
var partida_encerrada := false
var chefe_apareceu := false
var chefe_derrotado := false
var clima_atual: Control
# Nome do marcador -> horario em segundos ate o qual ele fica bloqueado.
var pontos_bloqueados_ate: Dictionary = {}
var chefe: CharacterBody2D

# Interface visual criada por codigo: nenhuma edicao na cena e necessaria.
var ui_vida: Label
var ui_abates: Label
var ui_itens: Label
var ui_progresso: ProgressBar
var ui_gelo: Label
var ui_gelo_barra: ProgressBar
var ui_boss_painel: PanelContainer
var ui_boss_barra: ProgressBar
var ui_boss_vida: Label
var ui_estado: Label

@onready var horda: Timer = $Horda
@onready var relogio: Timer = $Relogio
@onready var jogador = $Jogador
@onready var texto_vida: Label = $HUD/Vida
@onready var texto_tempo: Label = $HUD/Tempo

# HUD discreta: texto neutro, espaçamento reduzido e barras finas.
const TEXTO := Color("e0e5e8")
const SECUNDARIO := Color("a1aeb5")
const BARRA := Color("a7b7bd")
const FUNDO_BARRA := Color(0.26, 0.32, 0.35, 0.55)
const ALERTA := Color("c8a4a4")

const NEVASCA = preload("res://scripts/nevasca.gd")

func _ready() -> void:
	criar_hud()
	criar_nevasca()

func criar_nevasca() -> void:
	# A camada 0 fica sobre o mundo, mas abaixo da HUD (camada 1).
	var camada := CanvasLayer.new()
	camada.name = "ClimaNevasca"
	camada.layer = 0
	add_child(camada)
	var clima: Control = NEVASCA.new()
	clima.name = "Nevasca"
	clima.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(clima)
	clima.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clima_atual = clima


func criar_texto(conteudo: String, tamanho: int, cor: Color, alinhamento: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var rotulo := Label.new()
	rotulo.text = conteudo
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = alinhamento
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo

func criar_barra(cor: Color, altura: float = 4.0) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, altura)
	barra.min_value = 0.0
	barra.max_value = 100.0
	barra.value = 100.0
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = FUNDO_BARRA
	fundo.set_corner_radius_all(2)
	barra.add_theme_stylebox_override("background", fundo)
	var preenchimento := StyleBoxFlat.new()
	preenchimento.bg_color = cor
	preenchimento.set_corner_radius_all(2)
	barra.add_theme_stylebox_override("fill", preenchimento)
	return barra

func criar_hud() -> void:
	# Mantem os nos originais para nao quebrar as referencias da cena.
	texto_vida.hide()
	texto_tempo.hide()
	var anterior := $HUD.get_node_or_null("HUDPolar")
	if anterior != null:
		anterior.queue_free()

	var raiz := Control.new()
	raiz.name = "HUDMinimalista"
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Superior esquerdo: somente vida e abates, sem moldura.
	var status := VBoxContainer.new()
	status.position = Vector2(22, 18)
	status.add_theme_constant_override("separation", 5)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(status)
	ui_vida = criar_texto("VIDA  3/3", 17, TEXTO)
	status.add_child(ui_vida)
	ui_abates = criar_texto("Abates  0 / 8", 12, SECUNDARIO)
	status.add_child(ui_abates)
	ui_estado = criar_texto("", 11, ALERTA)
	status.add_child(ui_estado)

	# Superior direito: contador + linha fina de progresso.
	var objetivo := VBoxContainer.new()
	objetivo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	objetivo.offset_left = -182.0
	objetivo.offset_right = -22.0
	objetivo.offset_top = 20.0
	objetivo.offset_bottom = 66.0
	objetivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objetivo.add_theme_constant_override("separation", 7)
	raiz.add_child(objetivo)
	ui_itens = criar_texto("ITENS  0 / 20", 15, TEXTO, HORIZONTAL_ALIGNMENT_RIGHT)
	objetivo.add_child(ui_itens)
	ui_progresso = criar_barra(BARRA, 3.0)
	objetivo.add_child(ui_progresso)

	# Inferior esquerdo: o indicador da habilidade nao precisa de painel.
	var poder := VBoxContainer.new()
	poder.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	poder.offset_left = 22.0
	poder.offset_right = 180.0
	poder.offset_top = -57.0
	poder.offset_bottom = -18.0
	poder.add_theme_constant_override("separation", 6)
	poder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(poder)
	ui_gelo = criar_texto("Q  •  Gelo pronto", 12, SECUNDARIO)
	poder.add_child(ui_gelo)
	ui_gelo_barra = criar_barra(BARRA, 3.0)
	poder.add_child(ui_gelo_barra)

	# Chefe: barra compacta no topo, visivel somente durante o confronto.
	ui_boss_painel = PanelContainer.new()
	var sem_painel := StyleBoxEmpty.new()
	ui_boss_painel.add_theme_stylebox_override("panel", sem_painel)
	ui_boss_painel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ui_boss_painel.offset_left = -130.0
	ui_boss_painel.offset_right = 130.0
	ui_boss_painel.offset_top = 18.0
	ui_boss_painel.offset_bottom = 54.0
	ui_boss_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(ui_boss_painel)
	var chefe_conteudo := VBoxContainer.new()
	chefe_conteudo.add_theme_constant_override("separation", 6)
	ui_boss_painel.add_child(chefe_conteudo)
	ui_boss_vida = criar_texto("FOCA MUTANTE", 12, TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
	chefe_conteudo.add_child(ui_boss_vida)
	ui_boss_barra = criar_barra(ALERTA, 5.0)
	chefe_conteudo.add_child(ui_boss_barra)
	ui_boss_painel.hide()

func _process(_delta: float) -> void:
	ui_vida.text = "VIDA  %d/3" % maxi(0, jogador.vida)
	ui_abates.text = "Abates  %d / %d" % [abates, meta_total_abates()] if abates < meta_total_abates() else "Abates  %d" % abates
	ui_itens.text = "ITENS  %d / %d" % [coletados, objetivo_itens]
	ui_progresso.value = 100.0 * float(coletados) / float(maxi(1, objetivo_itens))
	ui_estado.text = mensagem_objetivo()

	var recarga: float = maxf(0.01, jogador.recarga_gelo)
	var restante: float = jogador.tempo_restante_gelo
	ui_gelo_barra.value = 100.0 * (1.0 - clampf(restante / recarga, 0.0, 1.0))
	if jogador.cena_projetil_gelo == null:
		ui_gelo.text = "Q  •  Gelo indisponível"
	elif restante > 0.0:
		ui_gelo.text = "Q  •  Gelo  %.1fs" % restante
	else:
		ui_gelo.text = "Q  •  Gelo pronto"

	var chefe_vivo := is_instance_valid(chefe) and not chefe.is_queued_for_deletion()
	ui_boss_painel.visible = chefe_vivo
	if chefe_vivo:
		ui_boss_barra.value = 100.0 * float(maxi(0, chefe.vida)) / float(maxi(1, vida_chefe))

# A exigencia so sobe a cada bloco de itens; nunca consome abates.
func meta_total_abates() -> int:
	# A ultima etapa nao exige abates adicionais depois de chegar aos 20 itens.
	# Ex.: 20 itens em etapas de 5, 2 abates/etapa => 6 abates no total.
	var etapas_antes_final: int = maxi(0, int(ceil(float(objetivo_itens) / float(maxi(1, itens_por_etapa)))) - 1)
	return maxi(0, abates_por_etapa) * etapas_antes_final

func meta_abates_para_coletar() -> int:
	var etapas_completas := int(coletados / maxi(1, itens_por_etapa))
	return mini(meta_total_abates(), etapas_completas * maxi(0, abates_por_etapa))

func pode_coletar() -> bool:
	return not partida_encerrada and coletados < objetivo_itens and abates >= meta_abates_para_coletar()

func mensagem_objetivo() -> String:
	if coletados >= objetivo_itens:
		if abates < meta_total_abates():
			return "EXTRACAO  •  Elimine %d focas" % (meta_total_abates() - abates)
		if exigir_derrotar_chefe and chefe_apareceu and not chefe_derrotado:
			return "EXTRACAO  •  Derrote a mutante"
		return ""
	if not pode_coletar():
		return "CONTENCAO  •  Elimine %d focas" % (meta_abates_para_coletar() - abates)
	if chefe_apareceu and not chefe_derrotado:
		return "Mutante na base"
	return ""

func tentar_vencer() -> void:
	if coletados < objetivo_itens or abates < meta_total_abates():
		return
	if exigir_derrotar_chefe and chefe_apareceu and not chefe_derrotado:
		return
	vencer()

func intensidade_da_nevasca() -> float:
	if is_instance_valid(clima_atual):
		return float(clima_atual.get("intensidade"))
	return 0.0

func inimigo_morreu(inimigo: Node2D) -> void:
	if partida_encerrada:
		return
	abates += 1
	if inimigo == chefe:
		chefe_derrotado = true
		chefe = null
	tentar_vencer()

func _on_horda_timeout() -> void:
	if partida_encerrada or cena_inimigo == null:
		return
	if get_tree().get_nodes_in_group("inimigos").size() >= max_inimigos:
		return
	var pontos := $Nascedouros.get_children()
	if pontos.is_empty():
		return
	var inimigo = cena_inimigo.instantiate()
	add_child(inimigo)
	inimigo.global_position = pontos.pick_random().global_position
	horda.wait_time = maxf(0.5, horda.wait_time * 0.95)

func _on_relogio_timeout() -> void:
	# Ganhar exige os 20 itens. Para usar o relogio como limite, chame perder().
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

	# Nao deixa acumular itens ilimitados nem criar mais itens do que falta coletar.
	var ativos := get_tree().get_nodes_in_group("coletaveis")
	var restantes: int = objetivo_itens - coletados
	if ativos.size() >= mini(max_itens_ativos, restantes):
		return

	var agora: float = Time.get_ticks_msec() / 1000.0
	var candidatos: Array[Node2D] = []
	for ponto in $Pontos.get_children():
		if not ponto is Node2D:
			continue
		if agora < float(pontos_bloqueados_ate.get(ponto.name, 0.0)):
			continue
		if ponto.global_position.distance_to(jogador.global_position) < distancia_minima_jogador_item:
			continue
		var ocupado := false
		for outro in ativos:
			if is_instance_valid(outro) and not outro.is_queued_for_deletion():
				if outro.global_position.distance_to(ponto.global_position) < 24.0:
					ocupado = true
					break
		if not ocupado:
			candidatos.append(ponto)

	# Sem local seguro disponivel: aguarda o proximo timeout do Timer Itens.
	if candidatos.is_empty():
		return

	var escolhido: Node2D = candidatos.pick_random()
	var novo_item = cena_item.instantiate()
	novo_item.set("ponto_spawn", escolhido.name)
	add_child(novo_item)
	novo_item.global_position = escolhido.global_position

func coletou(item_coletado: Area2D) -> void:
	if partida_encerrada:
		return

	# Impede reutilizar imediatamente o ponto onde o jogador acabou de coletar.
	if item_coletado.get("ponto_spawn") != &"":
		var agora: float = Time.get_ticks_msec() / 1000.0
		pontos_bloqueados_ate[item_coletado.get("ponto_spawn")] = agora + maxf(0.0, espera_reutilizar_ponto)

	if not pode_coletar():
		return
	coletados += 1
	if coletados >= objetivo_itens:
		tentar_vencer()
		return
	if coletados >= itens_para_chefe and not chefe_apareceu:
		chefe_apareceu = true
		criar_chefe.call_deferred()

func criar_chefe() -> void:
	if partida_encerrada or cena_inimigo == null:
		return
	var pontos := $Nascedouros.get_children()
	if pontos.is_empty():
		return
	# Se o limite estiver cheio, retira um inimigo normal para dar lugar ao chefe.
	if get_tree().get_nodes_in_group("inimigos").size() >= max_inimigos:
		for inimigo in get_tree().get_nodes_in_group("inimigos"):
			if inimigo != chefe:
				inimigo.queue_free()
				break
	var novo_chefe = cena_inimigo.instantiate()
	novo_chefe.name = "FocaMutante"
	novo_chefe.vida = vida_chefe
	novo_chefe.velocidade = velocidade_chefe
	add_child(novo_chefe)
	novo_chefe.global_position = pontos.pick_random().global_position
	novo_chefe.scale = Vector2(1.65, 1.65)
	novo_chefe.modulate = Color(1.0, 0.45, 0.55)
	novo_chefe.add_to_group("chefe")
	chefe = novo_chefe
