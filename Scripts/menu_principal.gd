extends Control
## Menú principal (portada) de EcoGuardián: Jugar, Cómo jugar y Salir.
## Muestra el mejor puntaje guardado y un botón para silenciar el sonido.
## Si el nivel 2 ya está desbloqueado, "Jugar" abre un selector de nivel.
## También conecta con la evaluación: trivia inicial antes de la primera partida,
## acceso a la trivia final y a la pantalla de resultados para el docente.
## El paisaje del fondo se pinta por código en dos TileMapLayer.

const RUTA_JUEGO := "res://Escenas/Juego.tscn"
const RUTA_TRIVIA := "res://Escenas/Interfaz/Trivia.tscn"
const RUTA_RESULTADOS := "res://Escenas/Interfaz/Resultados.tscn"
const FUENTE := 0

## Los 5 estilos de portada (fondos generados por Scripts/Herramientas/Python/generar_portadas.py).
## Se elige con la propiedad "Estilo Portada" del nodo raíz MenuPrincipal.
const PORTADAS := [
	{
		"nombre": "Amanecer en el Nevado", "fondo": preload("res://Assets/portada_1.png"),
		"titulo": Color(1, 0.96, 0.72), "contorno": Color(0.09, 0.24, 0.13), "subtitulo": Color(0.85, 1, 0.75),
		"paisaje": Color(1, 1, 1), "agua": Color(0.22, 0.58, 0.86), "nubes": Color(1, 1, 1, 1), "luciernagas": false, "pueblo": false,
	},
	{
		"nombre": "Atardecer cafetero", "fondo": preload("res://Assets/portada_2.png"),
		"titulo": Color(1, 0.9, 0.68), "contorno": Color(0.26, 0.08, 0.28), "subtitulo": Color(1, 0.8, 0.62),
		"paisaje": Color(1, 0.8, 0.74), "agua": Color(0.62, 0.44, 0.62), "nubes": Color(1, 0.72, 0.62, 0.75), "luciernagas": false, "pueblo": false,
	},
	{
		"nombre": "Noche de luciérnagas", "fondo": preload("res://Assets/portada_3.png"),
		"titulo": Color(0.78, 0.96, 1), "contorno": Color(0.04, 0.08, 0.24), "subtitulo": Color(1, 0.92, 0.55),
		"paisaje": Color(0.45, 0.52, 0.8), "agua": Color(0.12, 0.2, 0.42), "nubes": Color(0.45, 0.5, 0.72, 0.45), "luciernagas": true, "pueblo": false,
	},
	{
		"nombre": "Valle de Cocora", "fondo": preload("res://Assets/portada_4.png"),
		"titulo": Color(1, 1, 1), "contorno": Color(0.08, 0.34, 0.14), "subtitulo": Color(1, 0.95, 0.55),
		"paisaje": Color(1, 1, 1), "agua": Color(0.22, 0.6, 0.84), "nubes": Color(1, 1, 1, 0.9), "luciernagas": false, "pueblo": false,
	},
	{
		"nombre": "El pueblo", "fondo": preload("res://Assets/portada_5.png"),
		"titulo": Color(1, 0.9, 0.4), "contorno": Color(0.36, 0.12, 0.05), "subtitulo": Color(1, 1, 0.92),
		"paisaje": Color(1, 0.97, 0.92), "agua": Color(0.2, 0.62, 0.72), "nubes": Color(1, 1, 1, 0.9), "luciernagas": false, "pueblo": true,
	},
]

@export var textura_estrella_llena: Texture2D
@export var textura_estrella_vacia: Texture2D
@export_range(1, 5) var estilo_portada := 1   ## ver PORTADAS

@onready var titulo: Label = $Titulo
@onready var boton_jugar: Button = $Botones/Jugar
@onready var boton_ayuda: Button = $Botones/ComoJugar
@onready var boton_salir: Button = $Botones/Salir
@onready var record: Label = $Record/Texto
@onready var estrellas: HBoxContainer = $Record/Estrellas
@onready var panel_ayuda: Panel = $PanelAyuda
@onready var boton_volver: Button = $PanelAyuda/Contenido/Volver
@onready var suelo: TileMapLayer = $Paisaje/Suelo
@onready var agua: TileMapLayer = $Paisaje/Agua
@onready var obstaculos: TileMapLayer = $Paisaje/Obstaculos
@onready var guardian: AnimatedSprite2D = $Paisaje/Guardian
@onready var basura_rio: Sprite2D = $Paisaje/BasuraRio
@onready var boton_resultados: Button = $Resultados
@onready var participante: VBoxContainer = $Participante
@onready var nombre_participante: Label = $Participante/Nombre
@onready var boton_trivia_final: Button = $Participante/Acciones/TriviaFinal
@onready var boton_cambiar: Button = $Participante/Acciones/Cambiar
@onready var nubes: Array[Sprite2D] = [$Nubes/Nube1, $Nubes/Nube2, $Nubes/Nube3]
@onready var logo: TextureRect = $Logo
@onready var portada: TextureRect = $Portada
@onready var subtitulo: Label = $Subtitulo
@onready var paisaje: Node2D = $Paisaje

var _selector: Panel
var _aviso_selector: Label


func _ready() -> void:
	get_tree().paused = false
	boton_jugar.pressed.connect(_jugar)
	boton_ayuda.pressed.connect(_abrir_ayuda)
	boton_salir.pressed.connect(_salir)
	boton_volver.pressed.connect(_cerrar_ayuda)
	boton_resultados.pressed.connect(_abrir_resultados)
	boton_trivia_final.pressed.connect(_abrir_trivia_final)
	boton_cambiar.pressed.connect(_cambiar_participante)
	_actualizar_participante()
	panel_ayuda.visible = false
	if OS.has_feature("web"):
		boton_salir.hide()  # En navegador no se puede cerrar la ventana

	# Récord guardado en disco
	if Guardado.partidas_jugadas == 0:
		record.text = "¡Primera partida!"
	else:
		record.text = "Mejor puntaje: %d" % Guardado.mejor_puntaje
	for i in estrellas.get_child_count():
		var estrella := estrellas.get_child(i) as TextureRect
		estrella.texture = textura_estrella_llena if i < Guardado.mejores_estrellas else textura_estrella_vacia

	_aplicar_portada()
	_animar_decoracion()
	Sonido.reproducir_musica()
	boton_jugar.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if panel_ayuda.visible and event.is_action_pressed("pausa"):
		_cerrar_ayuda()
	elif _selector != null and _selector.visible and event.is_action_pressed("pausa"):
		_cerrar_selector()


func _aplicar_portada() -> void:
	var estilo: Dictionary = PORTADAS[clampi(estilo_portada, 1, PORTADAS.size()) - 1]
	portada.texture = estilo["fondo"]
	titulo.label_settings.font_color = estilo["titulo"]
	titulo.label_settings.outline_color = estilo["contorno"]
	subtitulo.label_settings.font_color = estilo["subtitulo"]
	subtitulo.label_settings.outline_color = estilo["contorno"]
	paisaje.modulate = estilo["paisaje"]
	# El shader del agua no usa el tinte del nodo: el color se le pasa aparte
	var material_agua := agua.material as ShaderMaterial
	if material_agua != null:
		material_agua.set_shader_parameter("color_limpio", estilo["agua"])
	for nube in nubes:
		nube.self_modulate = estilo["nubes"]
	if estilo["pueblo"]:
		_pintar_paisaje_pueblo()
	else:
		_pintar_paisaje()
	if estilo["luciernagas"]:
		var luciernagas := Luciernagas.new()
		add_child(luciernagas)
		move_child(luciernagas, paisaje.get_index() + 1)


## Versión del pueblo: calle de adoquín, andén, malecón de ladrillo, faroles y guayacanes.
func _pintar_paisaje_pueblo() -> void:
	for x in range(-1, 21):
		suelo.set_cell(Vector2i(x, 7), FUENTE, Vector2i(4, 1))   # andén
		suelo.set_cell(Vector2i(x, 8), FUENTE, Vector2i(7, 0))   # adoquín
		suelo.set_cell(Vector2i(x, 9), FUENTE, Vector2i(5, 1))   # malecón
		agua.set_cell(Vector2i(x, 10), FUENTE, Vector2i(0, 1))
		agua.set_cell(Vector2i(x, 11), FUENTE, Vector2i(0, 1))
	for x in [1, 6, 14, 19]:
		obstaculos.set_cell(Vector2i(x, 7), FUENTE, Vector2i(6, 2))   # guayacanes
	for x in [3, 9, 12, 17]:
		obstaculos.set_cell(Vector2i(x, 7), FUENTE, Vector2i(7, 2))   # faroles


func _pintar_paisaje() -> void:
	for x in range(-1, 21):
		suelo.set_cell(Vector2i(x, 7), FUENTE, Vector2i(0, 0))
		suelo.set_cell(Vector2i(x, 8), FUENTE, Vector2i(1, 0) if x % 3 == 0 else Vector2i(0, 0))
		suelo.set_cell(Vector2i(x, 9), FUENTE, Vector2i(5, 0))
		agua.set_cell(Vector2i(x, 10), FUENTE, Vector2i(0, 1))
		agua.set_cell(Vector2i(x, 11), FUENTE, Vector2i(0, 1))
	for x in [0, 2, 5, 15, 18, 19]:
		obstaculos.set_cell(Vector2i(x, 7), FUENTE, Vector2i(0, 2))   # árboles
	for x in [3, 16]:
		obstaculos.set_cell(Vector2i(x, 7), FUENTE, Vector2i(1, 2))   # guaduas
	for x in [7, 8, 12]:
		obstaculos.set_cell(Vector2i(x, 7), FUENTE, Vector2i(3, 2))   # cafetos


func _animar_decoracion() -> void:
	# El logo (hoja con gota) se ubica justo a la izquierda del título
	var fuente := titulo.label_settings.font if titulo.label_settings.font != null else titulo.get_theme_font("font")
	var ancho_titulo := fuente.get_string_size(titulo.text, HORIZONTAL_ALIGNMENT_LEFT, -1, titulo.label_settings.font_size).x
	logo.position.x = 160.0 - ancho_titulo / 2.0 - logo.size.x - 3.0
	# Título y logo flotan juntos; el logo además se mece
	for nodo in [titulo, logo]:
		var flotar := create_tween().set_loops()
		flotar.tween_property(nodo, "position:y", nodo.position.y - 3.0, 1.2).set_trans(Tween.TRANS_SINE)
		flotar.tween_property(nodo, "position:y", nodo.position.y, 1.2).set_trans(Tween.TRANS_SINE)
	logo.pivot_offset = logo.size / 2.0
	var mecer := create_tween().set_loops()
	mecer.tween_property(logo, "rotation", 0.12, 1.5).set_trans(Tween.TRANS_SINE)
	mecer.tween_property(logo, "rotation", -0.12, 1.5).set_trans(Tween.TRANS_SINE)
	# Las nubes cruzan el cielo despacio, cada una a su ritmo
	for i in nubes.size():
		var nube := nubes[i]
		var viaje := create_tween().set_loops()
		var duracion := 70.0 + i * 25.0
		var faltante := (360.0 - nube.position.x) / 400.0
		viaje.tween_property(nube, "position:x", 360.0, duracion * faltante)
		viaje.tween_property(nube, "position:x", 360.0, duracion).from(-40.0)
	# El guardián camina de un lado al otro
	var caminar := create_tween().set_loops()
	caminar.tween_callback(guardian.play.bind("caminar_derecha"))
	caminar.tween_property(guardian, "position:x", 250.0, 5.0)
	caminar.tween_callback(guardian.play.bind("quieto_abajo"))
	caminar.tween_interval(0.8)
	caminar.tween_callback(guardian.play.bind("caminar_izquierda"))
	caminar.tween_property(guardian, "position:x", 70.0, 5.0)
	caminar.tween_callback(guardian.play.bind("quieto_abajo"))
	caminar.tween_interval(0.8)
	# Una botella baja por el río
	var rio := create_tween().set_loops()
	rio.tween_property(basura_rio, "position:x", 340.0, 14.0).from(-20.0)


func _jugar() -> void:
	Sonido.reproducir("boton", false)
	if Evaluacion.necesita_trivia_inicial():
		# Participante nuevo: primero la trivia inicial (pre-test) y luego el nivel 1
		Evaluacion.modo = Evaluacion.Modo.INICIAL
		Transicion.cambiar_escena(RUTA_TRIVIA)
	elif Guardado.nivel_desbloqueado >= 2:
		_abrir_selector()
	else:
		_jugar_nivel(1)


func _jugar_nivel(nivel: int) -> void:
	Guardado.nivel_actual = nivel
	Transicion.cambiar_escena(RUTA_JUEGO)


# ================================================================= SELECTOR DE NIVEL
func _abrir_selector() -> void:
	if _selector == null:
		_crear_selector()
	_aviso_selector.text = ""
	_selector.visible = true
	_selector.get_node("Contenido/Niveles").get_child(Guardado.nivel_desbloqueado - 1).grab_focus()


func _cerrar_selector() -> void:
	Sonido.reproducir("boton", false)
	_selector.visible = false
	boton_jugar.grab_focus()


func _crear_selector() -> void:
	_selector = Panel.new()
	_selector.add_theme_stylebox_override("panel", panel_ayuda.get_theme_stylebox("panel"))
	_selector.position = Vector2(46, 44)
	_selector.size = Vector2(228, 102)
	add_child(_selector)
	var contenido := VBoxContainer.new()
	contenido.name = "Contenido"
	contenido.position = Vector2(6, 4)
	contenido.size = Vector2(216, 94)
	contenido.add_theme_constant_override("separation", 3)
	_selector.add_child(contenido)
	var titulo_selector := Label.new()
	titulo_selector.text = "ELIGE EL NIVEL"
	titulo_selector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_selector.add_theme_font_size_override("font_size", 11)
	titulo_selector.add_theme_color_override("font_color", Color(1, 0.88, 0.4))
	contenido.add_child(titulo_selector)
	var niveles := HBoxContainer.new()
	niveles.name = "Niveles"
	niveles.alignment = BoxContainer.ALIGNMENT_CENTER
	niveles.add_theme_constant_override("separation", 8)
	contenido.add_child(niveles)
	for nivel in range(1, Niveles.cantidad() + 1):
		var datos := Niveles.datos(nivel)
		var bloqueado := nivel > Guardado.nivel_desbloqueado
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(100, 46)
		boton.text = "%s\n%s" % [datos["titulo"], "Bloqueado" if bloqueado else datos["nombre"]]
		boton.add_theme_font_size_override("font_size", 8)
		if bloqueado:
			boton.modulate = Color(0.6, 0.6, 0.6)
		boton.pressed.connect(_elegir_nivel.bind(nivel))
		niveles.add_child(boton)
	_aviso_selector = Label.new()
	_aviso_selector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_selector.add_theme_font_size_override("font_size", 7)
	_aviso_selector.add_theme_color_override("font_color", Color(1, 0.6, 0.5))
	contenido.add_child(_aviso_selector)
	var volver := Button.new()
	volver.text = "Volver (Esc)"
	volver.add_theme_font_size_override("font_size", 8)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(_cerrar_selector)
	contenido.add_child(volver)


func _elegir_nivel(nivel: int) -> void:
	if nivel > Guardado.nivel_desbloqueado:
		Sonido.reproducir("error", false)
		_aviso_selector.text = "Gana el nivel %d para desbloquearlo" % (nivel - 1)
		return
	Sonido.reproducir("boton", false)
	_jugar_nivel(nivel)


## Muestra quién está jugando y si le falta la trivia final.
func _actualizar_participante() -> void:
	participante.visible = Evaluacion.activa and Evaluacion.hay_participante()
	if not participante.visible:
		return
	nombre_participante.text = "Jugando: %s" % Evaluacion.nombre_actual()
	boton_trivia_final.visible = Evaluacion.trivia_final_pendiente()


func _abrir_trivia_final() -> void:
	Sonido.reproducir("boton", false)
	Evaluacion.modo = Evaluacion.Modo.FINAL
	Transicion.cambiar_escena(RUTA_TRIVIA)


## Otro estudiante va a jugar: el siguiente "Jugar" pide nombre y trivia inicial.
func _cambiar_participante() -> void:
	Sonido.reproducir("boton", false)
	Evaluacion.cambiar_participante()
	_actualizar_participante()
	boton_jugar.grab_focus()


func _abrir_resultados() -> void:
	Sonido.reproducir("boton", false)
	Transicion.cambiar_escena(RUTA_RESULTADOS)


func _abrir_ayuda() -> void:
	Sonido.reproducir("boton", false)
	panel_ayuda.visible = true
	boton_volver.grab_focus()


func _cerrar_ayuda() -> void:
	Sonido.reproducir("boton", false)
	panel_ayuda.visible = false
	boton_ayuda.grab_focus()


func _salir() -> void:
	Sonido.salir_del_juego()


## Luciérnagas que titilan sobre el paisaje (sólo en la portada de noche).
class Luciernagas extends Node2D:
	var _puntos: Array[Vector3] = []   # x, y, fase
	var _tiempo := 0.0

	func _ready() -> void:
		for i in 16:
			_puntos.append(Vector3(randf_range(0, 320), randf_range(60, 160), randf() * TAU))

	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()

	func _draw() -> void:
		for p in _puntos:
			var brillo := 0.5 + 0.5 * sin(_tiempo * 2.5 + p.z * 3.0)
			var posicion := Vector2(p.x + sin(_tiempo * 0.6 + p.z) * 8.0, p.y + cos(_tiempo * 0.8 + p.z) * 5.0)
			posicion = posicion.round()
			draw_rect(Rect2(posicion - Vector2(1, 1), Vector2(3, 3)), Color(1, 0.9, 0.3, 0.25 * brillo))
			draw_rect(Rect2(posicion, Vector2(1, 1)), Color(1, 1, 0.6, brillo))
