extends Control

const CENARIO: String = "res://scenes/scneario.tscn"
const COR_FUNDO: Color = Color("111b25")
const COR_TEXTO: Color = Color("e2e9ec")
const COR_SECUNDARIA: Color = Color("9caeb7")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    _montar_tela()

func _montar_tela() -> void:
    var fundo: ColorRect = ColorRect.new()
    fundo.color = COR_FUNDO
    fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(fundo)
    move_child(fundo, 0)

    var centro: CenterContainer = CenterContainer.new()
    centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(centro)

    var coluna: VBoxContainer = VBoxContainer.new()
    coluna.custom_minimum_size = Vector2(330, 0)
    coluna.add_theme_constant_override("separation", 16)
    centro.add_child(coluna)

    var titulo: Label = Label.new()
    titulo.text = "ZOMBIFOCADO"
    titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    titulo.add_theme_font_size_override("font_size", 38)
    titulo.add_theme_color_override("font_color", COR_TEXTO)
    coluna.add_child(titulo)

    var subtitulo: Label = Label.new()
    subtitulo.text = "BASE ARTICA  /  SOBREVIVENCIA"
    subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitulo.add_theme_font_size_override("font_size", 13)
    subtitulo.add_theme_color_override("font_color", COR_SECUNDARIA)
    coluna.add_child(subtitulo)

    var espaco: Control = Control.new()
    espaco.custom_minimum_size.y = 20
    coluna.add_child(espaco)

    var jogar: Button = _botao("INICIAR EXPEDICAO")
    jogar.pressed.connect(_jogar)
    coluna.add_child(jogar)

    var ajuda: Label = Label.new()
    ajuda.text = "WASD / SETAS  -  MOVER\nESPACO / CLIQUE  -  ATAQUE\nQ  -  PODER DE GELO\nCOLETE 20 SUPRIMENTOS E SOBREVIVA"
    ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ajuda.add_theme_font_size_override("font_size", 12)
    ajuda.add_theme_color_override("font_color", COR_SECUNDARIA)
    coluna.add_child(ajuda)
    jogar.grab_focus.call_deferred()

func _botao(texto: String) -> Button:
    var botao: Button = Button.new()
    botao.text = texto
    botao.custom_minimum_size = Vector2(0, 48)
    botao.add_theme_font_size_override("font_size", 17)
    return botao

func _jogar() -> void:
    get_tree().change_scene_to_file(CENARIO)
