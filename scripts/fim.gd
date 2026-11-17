extends Control

const CENARIO: String = "res://scenes/scneario.tscn"
const MENU: String = "res://scenes/menu.tscn"

func _ready() -> void:
	# As duas cenas existentes ja tem um Label com o texto da derrota/vitoria.
	var rotulo_original: Label = get_node_or_null("Label") as Label
	var venceu: bool = get_tree().current_scene.scene_file_path.ends_with("vitoria.tscn")
	if rotulo_original != null:
		venceu = rotulo_original.text.to_lower().contains("venceu")
		rotulo_original.hide()

	var fundo: ColorRect = ColorRect.new()
	fundo.color = Color("111b25")
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	move_child(fundo, 0)

	var centro: CenterContainer = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.custom_minimum_size.x = 340
	coluna.add_theme_constant_override("separation", 16)
	centro.add_child(coluna)

	var titulo: Label = Label.new()
	titulo.text = "MISSAO CONCLUIDA" if venceu else "EXPEDICAO ENCERRADA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color("e2e9ec"))
	coluna.add_child(titulo)

	var descricao: Label = Label.new()
	descricao.text = "Voce recuperou os suprimentos." if venceu else "As focas dominaram a base."
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.add_theme_font_size_override("font_size", 15)
	descricao.add_theme_color_override("font_color", Color("9caeb7"))
	coluna.add_child(descricao)

	var espaco: Control = Control.new()
	espaco.custom_minimum_size.y = 15
	coluna.add_child(espaco)

	var reiniciar: Button = Button.new()
	reiniciar.text = "JOGAR NOVAMENTE"
	reiniciar.custom_minimum_size.y = 46
	reiniciar.pressed.connect(_reiniciar)
	coluna.add_child(reiniciar)

	var menu: Button = Button.new()
	menu.text = "MENU PRINCIPAL"
	menu.custom_minimum_size.y = 44
	menu.pressed.connect(_voltar_menu)
	coluna.add_child(menu)
	reiniciar.grab_focus.call_deferred()

func _reiniciar() -> void:
	get_tree().change_scene_to_file(CENARIO)

func _voltar_menu() -> void:
	get_tree().change_scene_to_file(MENU)
