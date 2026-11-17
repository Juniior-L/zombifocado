extends Node2D
## Corte glacial: um rastro luminoso que varre a frente do personagem.
## Sem texturas externas; usa a paleta do projetil de gelo.

var direcao: Vector2 = Vector2.DOWN
var raio: float = 56.0
var duracao: float = 0.24
var tempo: float = 0.0

func _ready() -> void:
	z_index = 9
	queue_redraw()

func _process(delta: float) -> void:
	tempo += delta
	if tempo >= duracao:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(tempo / duracao, 0.0, 1.0)
	var entrada := minf(1.0, t / 0.14)
	var fade := pow(1.0 - t, 1.2) * entrada
	var frente := direcao.normalized().angle()
	# A ponta avanca ao longo de um cone de aproximadamente 115 graus.
	var ponta := frente - 0.95 + t * 1.9
	var cauda := ponta - 0.82
	var passos := 22
	for i in range(passos):
		var u := float(i) / float(passos)
		var a := lerpf(cauda, ponta, u)
		var b := lerpf(cauda, ponta, float(i + 1) / float(passos))
		var peso := (0.22 + 0.78 * u) * fade
		var p1 := Vector2.from_angle(a) * raio
		var p2 := Vector2.from_angle(b) * raio
		# Halo, faixa principal e fio branco-azulado, como o poder de gelo.
		draw_line(p1, p2, Color(0.12, 0.58, 0.98, 0.23 * peso), 17.0, true)
		draw_line(p1, p2, Color(0.13, 0.73, 1.0, 0.57 * peso), 9.0, true)
		draw_line(p1, p2, Color(0.74, 0.96, 1.0, 0.98 * peso), 3.3, true)
		# Uma segunda laminazinha interna da profundidade ao efeito.
		draw_line(Vector2.from_angle(a) * (raio - 12.0), Vector2.from_angle(b) * (raio - 12.0), Color(0.23, 0.83, 1.0, 0.35 * peso), 3.0, true)
	# Tracos saindo da ponta do golpe.
	for i in range(6):
		var a := ponta - float(i) * 0.17
		var r := raio * (0.56 + float(i % 3) * 0.09)
		var p := Vector2.from_angle(a) * r
		var q := p + Vector2.from_angle(a + 0.20) * (6.0 + float(i % 2) * 5.0)
		draw_line(p, q, Color(0.58, 0.92, 1.0, (0.45 - float(i) * 0.045) * fade), 1.5, true)
	var estrela := Vector2.from_angle(ponta) * raio
	draw_circle(estrela, 7.0, Color(0.15, 0.76, 1.0, 0.18 * fade))
	draw_circle(estrela, 2.3, Color(0.88, 0.98, 1.0, 0.75 * fade))
