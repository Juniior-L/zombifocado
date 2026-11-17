extends Node2D
## Estilhacos curtos no ponto de impacto. Criado sob demanda pelo inimigo.

var duracao := 0.30
var tempo := 0.0
var direcao := Vector2.RIGHT
var particulas: Array[Dictionary] = []

func _ready() -> void:
	z_index = 12
	for i in range(11):
		var angulo := direcao.angle() + randf_range(-1.5, 1.5)
		particulas.append({"direcao": Vector2.from_angle(angulo), "vel": randf_range(35.0, 105.0), "tamanho": randf_range(1.0, 3.0)})

func _process(delta: float) -> void:
	tempo += delta
	if tempo >= duracao:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := tempo / duracao
	var alpha := pow(1.0 - t, 1.3)
	draw_circle(Vector2.ZERO, lerpf(5.0, 19.0, t), Color(0.32, 0.84, 1.0, 0.14 * alpha))
	for particula in particulas:
		var v: Vector2 = particula["direcao"]
		var p := v * float(particula["vel"]) * tempo
		draw_line(p - v * 3.0, p + v * float(particula["tamanho"]), Color(0.70, 0.95, 1.0, 0.85 * alpha), 1.6, true)
