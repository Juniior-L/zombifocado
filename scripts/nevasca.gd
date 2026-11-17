extends Control
## Nevasca forte de tela inteira: flocos com profundidade, vento e rajadas.
## Desenhada na camada climatica, abaixo da HUD. Sem texturas externas.

@export var intervalo_entre_nevascas: float = 42.0
@export var duracao_nevasca: float = 24.0
@export var tempo_transicao: float = 3.5
@export_range(0.0, 0.8) var opacidade_nevoa: float = 0.46
@export_range(150, 1100, 1) var quantidade_flocos: int = 660
@export var forca_vento: float = 280.0
@export var distancia_olhos: float = 260.0

var tempo_total := 0.0
var intensidade := 0.0
var flocos: Array[Dictionary] = []
var tamanho_anterior := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	inicializar_flocos()
	resized.connect(inicializar_flocos)

func inicializar_flocos() -> void:
	var dimensoes := get_viewport_rect().size
	if dimensoes.x <= 0.0 or dimensoes.y <= 0.0:
		return
	tamanho_anterior = dimensoes
	flocos.clear()
	for i in range(quantidade_flocos):
		var camada := randf()
		flocos.append({
			"pos": Vector2(randf_range(0.0, dimensoes.x), randf_range(0.0, dimensoes.y)),
			"profundidade": camada,
			"comprimento": lerpf(4.0, 23.0, camada),
			"espessura": lerpf(0.8, 2.0, camada),
			"alpha": lerpf(0.24, 0.80, camada),
			"fase": randf_range(0.0, TAU)
		})

func _process(delta: float) -> void:
	var ciclo := maxf(1.0, intervalo_entre_nevascas + duracao_nevasca)
	tempo_total += delta
	var em_nevasca := fmod(tempo_total, ciclo) >= intervalo_entre_nevascas
	var destino := 1.0 if em_nevasca else 0.0
	var antes := intensidade
	intensidade = move_toward(intensidade, destino, delta / maxf(0.1, tempo_transicao))
	if intensidade < 0.001:
		if antes > 0.001:
			queue_redraw()
		return
	var dim := get_viewport_rect().size
	if dim != tamanho_anterior:
		inicializar_flocos()
	var rajada := 0.85 + 0.26 * sin(tempo_total * 0.65) + 0.18 * sin(tempo_total * 2.2)
	for floco in flocos:
		var profundidade: float = floco["profundidade"]
		var pos: Vector2 = floco["pos"]
		var vel_x := -forca_vento * (0.38 + profundidade * 0.98) * rajada
		var vel_y := (35.0 + profundidade * 105.0) * (0.75 + 0.25 * rajada)
		pos += Vector2(vel_x, vel_y) * delta
		var margem := 35.0
		if pos.x < -margem:
			pos.x = dim.x + margem
			pos.y = randf_range(-margem, dim.y + margem)
		if pos.y > dim.y + margem:
			pos.y = -margem
			pos.x = randf_range(-margem, dim.x + margem)
		floco["pos"] = pos
	queue_redraw()

func _draw() -> void:
	if intensidade < 0.001:
		return
	var dim := get_viewport_rect().size
	var rajada := 0.85 + 0.26 * sin(tempo_total * 0.65) + 0.18 * sin(tempo_total * 2.2)
	# Bruma fria em toda a tela, com pulsos de vento que encobrem a paisagem.
	draw_rect(Rect2(Vector2.ZERO, dim), Color(0.78, 0.85, 0.89, opacidade_nevoa * intensidade))
	for faixa in range(5):
		var y := fposmod(tempo_total * (18.0 + faixa * 12.0) + faixa * dim.y / 5.0, dim.y + 160.0) - 80.0
		var op := (0.020 + 0.025 * sin(tempo_total * 1.5 + faixa)) * intensidade
		draw_rect(Rect2(Vector2(0, y), Vector2(dim.x, 46.0 + faixa * 7.0)), Color(0.93, 0.96, 0.98, maxf(0.0, op)))
	for floco in flocos:
		var p: Vector2 = floco["pos"]
		var prof: float = floco["profundidade"]
		var comprimento: float = floco["comprimento"]
		var alpha: float = floco["alpha"]
		var espessura: float = floco["espessura"]
		var deslocamento := Vector2(-comprimento * rajada, comprimento * (0.10 + prof * 0.20))
		draw_line(p, p + deslocamento, Color(0.96, 0.98, 1.0, alpha * intensidade), espessura, true)

	# Olhos de focas proximas surgem atraves da neve (sobrepostos a nevoa).
	# So aparecem durante a tempestade para criar tensao, nao um radar permanente.
	if intensidade < 0.40:
		return
	var cenario := get_tree().current_scene
	if cenario == null or not cenario.has_node("Jogador"):
		return
	var jogador: Node2D = cenario.get_node("Jogador")
	var transformacao: Transform2D = get_viewport().get_canvas_transform()
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not inimigo is Node2D or inimigo.is_queued_for_deletion():
			continue
		if jogador.global_position.distance_to(inimigo.global_position) > distancia_olhos:
			continue
		var p: Vector2 = transformacao * inimigo.global_position
		if p.x < -25 or p.y < -25 or p.x > dim.x + 25 or p.y > dim.y + 25:
			continue
		var op := (intensidade - 0.4) / 0.6
		var pulso := 0.75 + 0.25 * sin(tempo_total * 5.0 + p.x * 0.04)
		var separacao: float = 5.5 * float(inimigo.scale.x)
		for sinal in [-1.0, 1.0]:
			var olho := p + Vector2(sinal * separacao, -4.0)
			draw_circle(olho, 6.5, Color(0.8, 0.05, 0.08, 0.12 * op * pulso))
			draw_circle(olho, 2.3, Color(0.96, 0.17, 0.14, 0.90 * op * pulso))
