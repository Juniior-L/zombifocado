extends Area2D

# O ponto e informado pelo cenario quando o item nasce.
var ponto_spawn: StringName = &""
var coletado := false
var tempo_efeito := 0.0
var sprite_base_y := -2.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("coletaveis")
	# O item so fica coletavel apos a animacao de chegada.
	monitoring = false
	modulate.a = 0.0
	if sprite:
		sprite_base_y = sprite.position.y
		sprite.scale *= 0.35
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_SINE)
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale / 0.35, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	if is_inside_tree() and not coletado:
		monitoring = true

func _process(delta: float) -> void:
	if coletado:
		return
	tempo_efeito += delta
	if sprite:
		sprite.position.y = sprite_base_y + sin(tempo_efeito * 3.1) * 2.2
	queue_redraw()

func _draw() -> void:
	if coletado:
		return
	var pulso := 0.5 + 0.5 * sin(tempo_efeito * 3.4)
	var brilho := modulate.a
	draw_circle(Vector2(0, 3), 16.0 + pulso * 3.0, Color(0.18, 0.85, 1.0, 0.075 * brilho))
	draw_arc(Vector2(0, 3), 12.0 + pulso * 2.0, 0.0, TAU, 32, Color(0.45, 0.95, 1.0, (0.34 + 0.2 * pulso) * brilho), 1.6, true)
	for i in range(4):
		var angulo := tempo_efeito * 0.6 + i * TAU / 4.0
		var ponto := Vector2(cos(angulo), sin(angulo)) * (17.0 + pulso * 3.0)
		draw_circle(ponto, 1.5, Color(0.72, 1.0, 1.0, (0.4 + 0.4 * pulso) * brilho))

func _on_body_entered(corpo: Node2D) -> void:
	if coletado or not corpo.is_in_group("player"):
		return
	coletado = true
	monitoring = false
	get_tree().current_scene.coletou(self)
	queue_free()
