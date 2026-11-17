extends Area2D

# Ponto utilizado pelo gerenciador de spawn do cenario.
var ponto_spawn: StringName = &""
var coletado: bool = false
var tempo_efeito: float = 0.0
var sprite_base_y: float = -2.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("coletaveis")
	monitoring = false
	modulate.a = 0.0
	if sprite != null:
		sprite_base_y = sprite.position.y
		var escala_original: Vector2 = sprite.scale
		sprite.scale = escala_original * 0.35
		var animacao: Tween = create_tween().set_parallel(true)
		animacao.tween_property(self, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_SINE)
		animacao.tween_property(sprite, "scale", escala_original, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await animacao.finished
	else:
		var animacao: Tween = create_tween()
		animacao.tween_property(self, "modulate:a", 1.0, 0.42)
		await animacao.finished
	if is_inside_tree() and not coletado:
		# Alteracoes de monitoramento sao adiadas para fora do processamento fisico.
		set_deferred("monitoring", true)

func _process(delta: float) -> void:
	if coletado:
		return
	tempo_efeito += delta
	if sprite != null:
		sprite.position.y = sprite_base_y + sin(tempo_efeito * 3.1) * 2.2
	queue_redraw()

func _draw() -> void:
	if coletado:
		return
	var pulso: float = 0.5 + 0.5 * sin(tempo_efeito * 3.4)
	var brilho: float = modulate.a
	draw_circle(Vector2(0, 3), 16.0 + pulso * 3.0, Color(0.18, 0.85, 1.0, 0.075 * brilho))
	draw_arc(Vector2(0, 3), 12.0 + pulso * 2.0, 0.0, TAU, 32, Color(0.45, 0.95, 1.0, (0.34 + 0.2 * pulso) * brilho), 1.6, true)
	for i in range(4):
		var angulo: float = tempo_efeito * 0.6 + float(i) * TAU / 4.0
		var ponto: Vector2 = Vector2(cos(angulo), sin(angulo)) * (17.0 + pulso * 3.0)
		draw_circle(ponto, 1.5, Color(0.72, 1.0, 1.0, (0.4 + 0.4 * pulso) * brilho))

func _physics_process(_delta: float) -> void:
	if coletado or not monitoring or not _pode_coletar():
		return
	for corpo in get_overlapping_bodies():
		if corpo.is_in_group("player"):
			_on_body_entered(corpo)
			break

func _pode_coletar() -> bool:
	var cenario: Node = get_tree().current_scene
	return cenario != null and cenario.has_method("pode_coletar") and cenario.pode_coletar()

func _on_body_entered(corpo: Node2D) -> void:
	if coletado or not monitoring or not corpo.is_in_group("player"):
		return
	if not _pode_coletar():
		return
	coletado = true
	# NUNCA modificar monitoring diretamente no callback body_entered.
	set_deferred("monitoring", false)
	var cenario: Node = get_tree().current_scene
	if cenario != null and cenario.has_method("coletou"):
		cenario.coletou(self)
	queue_free()
