class_name Trivia
extends Control
## Trivia inicial (antes de jugar) y final (después de jugar).
## Usa los bancos de preguntas del autoload Evaluacion (uno para la inicial y
## otro distinto para la final). El modo se elige antes de cambiar de escena:
## Evaluacion.modo = Evaluacion.Modo.FINAL
##
## Fases:
##   INICIAL: REGISTRO (nombre) -> EXPLICACIÓN de las 3 canecas
##            -> PREGUNTAS (sin decir si acertó) -> LISTO -> Juego
##   FINAL:   PREGUNTAS (con retroalimentación) -> ENCUESTA -> COMPARACIÓN -> Menú
## La interfaz se construye por código dentro de Panel/Contenido.

enum Fase { REGISTRO, EXPLICACION, PREGUNTA, ENCUESTA, RESULTADO }

const RUTA_JUEGO := "res://Escenas/Juego.tscn"
const RUTA_MENU := "res://Escenas/MenuPrincipal.tscn"
const TEXTURA_RESIDUOS := preload("res://Assets/residuos.png")
const TEXTURA_CANECAS := preload("res://Assets/canecas.png")

const COLOR_TITULO := Color(1.0, 0.88, 0.4)
const COLOR_SUAVE := Color(0.75, 0.9, 0.85)
const COLOR_BIEN := Color(0.55, 1.0, 0.55)
const COLOR_MAL := Color(1.0, 0.5, 0.45)
const COLOR_ELEGIDO := Color(1.0, 0.9, 0.45)

var fase := Fase.REGISTRO
var nombre := ""
var respuestas: Array = []       ## respuesta elegida por pregunta (índice original, -1 = sin responder)
var valores_encuesta: Array = []
var _orden: Array = []           ## orden (barajado) en que se muestran las preguntas
var _paso := 0                   ## cuántas preguntas se han mostrado
var _botones_opcion: Array[Button] = []
var _opcion_de_boton: Array[int] = []   ## qué opción original representa cada botón
var _bloqueado := false
var _tiempo_inicio := 0
var _indice_registro := -1
var _aviso: Label

@onready var contenido: VBoxContainer = $Panel/Contenido


func _ready() -> void:
	get_tree().paused = false
	Sonido.reproducir_musica()
	respuestas.resize(Evaluacion.total_preguntas())
	respuestas.fill(-1)
	_orden = range(Evaluacion.total_preguntas())
	_orden.shuffle()
	if es_final() and not Evaluacion.hay_participante():
		Evaluacion.modo = Evaluacion.Modo.INICIAL  # Nadie hizo la inicial: se empieza por ahí
	if es_final():
		nombre = Evaluacion.nombre_actual()
		_empezar_preguntas()
	else:
		_mostrar_registro()


func es_final() -> bool:
	return Evaluacion.modo == Evaluacion.Modo.FINAL


func _unhandled_input(event: InputEvent) -> void:
	if fase == Fase.REGISTRO and event.is_action_pressed("pausa"):
		_ir_al_menu()
	elif fase == Fase.PREGUNTA and not _bloqueado:
		# Atajos 1-2-3 (las mismas teclas de las ranuras de la mochila)
		for i in 3:
			if event.is_action_pressed("ranura_%d" % (i + 1)) and i < _botones_opcion.size():
				_botones_opcion[i].pressed.emit()
				get_viewport().set_input_as_handled()
				return


# ================================================================= REGISTRO
func _mostrar_registro() -> void:
	fase = Fase.REGISTRO
	_limpiar()
	_titulo("TRIVIA INICIAL")
	_texto("Antes de jugar vas a conocer las 3 canecas y luego responderás %d preguntas rápidas. " % Evaluacion.total_preguntas()
		+ "Si no sabes alguna, no pasa nada: elige la que creas. Al final harás otra trivia para ver cuánto aprendiste.", 7)
	_espacio(4)
	_texto("Escribe tu nombre:", 8, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	var campo := LineEdit.new()
	campo.placeholder_text = "Nombre o código del estudiante"
	campo.max_length = 30
	campo.custom_minimum_size = Vector2(0, 16)
	campo.add_theme_font_size_override("font_size", 8)
	campo.text_submitted.connect(func(_texto_escrito: String): _comenzar_inicial(campo.text))
	contenido.add_child(campo)
	_espacio(4)
	var botones := _fila_botones()
	var volver := _boton("Volver (Esc)", botones)
	volver.pressed.connect(_ir_al_menu)
	var comenzar := _boton("Comenzar", botones)
	comenzar.pressed.connect(func(): _comenzar_inicial(campo.text))
	campo.grab_focus()


func _comenzar_inicial(texto: String) -> void:
	nombre = texto.strip_edges()
	if nombre.is_empty():
		nombre = "Participante %d" % (Evaluacion.registros.size() + 1)
	Sonido.reproducir("boton", false)
	_mostrar_explicacion()


# ================================================================= EXPLICACIÓN DE LAS CANECAS
## Antes de la trivia inicial: qué va en cada caneca, con el dibujo de cada residuo.
func _mostrar_explicacion() -> void:
	fase = Fase.EXPLICACION
	_limpiar()
	_titulo("LAS 3 CANECAS DE COLOMBIA")
	_texto("Así se separan los residuos desde 2021 (Resolución 2184 de 2019)", 6, COLOR_SUAVE)
	var columnas := HBoxContainer.new()
	columnas.alignment = BoxContainer.ALIGNMENT_CENTER
	columnas.add_theme_constant_override("separation", 5)
	contenido.add_child(columnas)
	var descripciones := ["Aprovechables, limpios y secos", "Orgánicos", "No aprovechables"]
	var todos: Array = Reciclaje.RESIDUOS + [Reciclaje.RESIDUO_BOLSA]
	for tipo in 3:
		columnas.add_child(_columna_caneca(tipo, descripciones[tipo], todos))
	var botones := _fila_botones()
	var listo := _boton("¡Entendido! A la trivia", botones)
	listo.pressed.connect(_empezar_preguntas)
	listo.grab_focus()


func _columna_caneca(tipo: int, descripcion: String, residuos: Array) -> PanelContainer:
	var color: Color = Reciclaje.COLOR_CANECA[tipo]
	var marco := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.07, 0.08)
	estilo.border_color = color
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(2)
	estilo.set_content_margin_all(3)
	marco.add_theme_stylebox_override("panel", estilo)
	marco.custom_minimum_size = Vector2(92, 0)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	marco.add_child(columna)
	# Encabezado: dibujo de la caneca + nombre + qué recibe
	var encabezado := HBoxContainer.new()
	encabezado.add_theme_constant_override("separation", 3)
	columna.add_child(encabezado)
	var icono := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = TEXTURA_CANECAS
	atlas.region = Rect2(tipo * 16, 0, 16, 24)
	icono.texture = atlas
	encabezado.add_child(icono)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", -2)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encabezado.add_child(textos)
	_texto(Reciclaje.nombre_caneca(tipo), 9, color, HORIZONTAL_ALIGNMENT_LEFT, textos)
	var detalle := _texto(descripcion, 6, COLOR_SUAVE, HORIZONTAL_ALIGNMENT_LEFT, textos)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle.custom_minimum_size = Vector2(66, 0)
	# Lista de residuos con su dibujo
	for residuo in residuos:
		if int(residuo["caneca"]) != tipo:
			continue
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 2)
		columna.add_child(fila)
		var dibujo := TextureRect.new()
		var cuadro := AtlasTexture.new()
		cuadro.atlas = TEXTURA_RESIDUOS
		cuadro.region = Rect2(int(residuo["cuadro"]) * 16, 0, 16, 16)
		dibujo.texture = cuadro
		dibujo.custom_minimum_size = Vector2(12, 12)
		dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(dibujo)
		var nombre_residuo := _texto(str(residuo["nombre"]), 6, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, fila)
		nombre_residuo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return marco


# ================================================================= PREGUNTAS
func _empezar_preguntas() -> void:
	_tiempo_inicio = Time.get_ticks_msec()
	_paso = 0
	_mostrar_pregunta()


func _mostrar_pregunta() -> void:
	fase = Fase.PREGUNTA
	_bloqueado = false
	_limpiar()
	var indice: int = _orden[_paso]
	var pregunta: Dictionary = Evaluacion.preguntas(es_final())[indice]

	# Encabezado: tipo de trivia y avance
	var encabezado := HBoxContainer.new()
	contenido.add_child(encabezado)
	var etiqueta := _texto("TRIVIA FINAL" if es_final() else "TRIVIA INICIAL", 7, COLOR_TITULO, HORIZONTAL_ALIGNMENT_LEFT, encabezado)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto("Pregunta %d de %d" % [_paso + 1, _orden.size()], 7, COLOR_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, encabezado)
	contenido.add_child(_barra_avance(float(_paso) / _orden.size()))

	# Ícono del residuo + enunciado
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.custom_minimum_size = Vector2(0, 34)
	contenido.add_child(fila)
	if int(pregunta["cuadro"]) >= 0:
		var icono := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = TEXTURA_RESIDUOS
		atlas.region = Rect2(int(pregunta["cuadro"]) * 16, 0, 16, 16)
		icono.texture = atlas
		icono.custom_minimum_size = Vector2(32, 32)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(icono)
	var enunciado := _texto(str(pregunta["texto"]), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, fila)
	enunciado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enunciado.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Opciones
	_botones_opcion.clear()
	_opcion_de_boton.clear()
	var opciones: Array = pregunta["opciones"]
	if opciones.is_empty():
		_crear_opciones_canecas()
	else:
		_crear_opciones_texto(opciones)
	for i in _botones_opcion.size():
		var boton := _botones_opcion[i]
		boton.pressed.connect(_responder.bind(indice, i))
	_botones_opcion[0].grab_focus()

	_aviso = _texto("Elige con el ratón, con las flechas + Enter o con las teclas 1-2-3", 6, COLOR_SUAVE)
	_aviso.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM


## Tres canecas una al lado de la otra (siempre en el mismo orden: blanca, verde, negra).
func _crear_opciones_canecas() -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	contenido.add_child(fila)
	for tipo in Evaluacion.NOMBRES_CANECAS.size():
		var atlas := AtlasTexture.new()
		atlas.atlas = TEXTURA_CANECAS
		atlas.region = Rect2(tipo * 16, 0, 16, 24)
		var boton := _boton("%d. %s" % [tipo + 1, Evaluacion.NOMBRES_CANECAS[tipo]], fila)
		boton.icon = atlas
		boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.custom_minimum_size = Vector2(62, 44)
		_botones_opcion.append(boton)
		_opcion_de_boton.append(tipo)


## Opciones de texto, en orden aleatorio.
func _crear_opciones_texto(opciones: Array) -> void:
	var orden := range(opciones.size())
	orden.shuffle()
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 3)
	contenido.add_child(columna)
	for i in orden.size():
		var original: int = orden[i]
		var boton := _boton("%d. %s" % [i + 1, opciones[original]], columna)
		boton.add_theme_font_size_override("font_size", 8)
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_botones_opcion.append(boton)
		_opcion_de_boton.append(original)


func _responder(indice_pregunta: int, numero_boton: int) -> void:
	if _bloqueado:
		return
	_bloqueado = true
	var elegida := _opcion_de_boton[numero_boton]
	respuestas[indice_pregunta] = elegida
	var boton := _botones_opcion[numero_boton]

	if not es_final():
		# Trivia inicial: no se dice si acertó, para medir lo que sabía antes de jugar
		Sonido.reproducir("boton", false)
		boton.modulate = COLOR_ELEGIDO
		var espera := create_tween()
		espera.tween_interval(0.25)
		espera.tween_callback(_siguiente_pregunta)
		return

	# Trivia final: retroalimentación inmediata
	var correcta := Evaluacion.es_correcta(indice_pregunta, elegida, true)
	Sonido.reproducir("acierto" if correcta else "error", false)
	for i in _botones_opcion.size():
		if Evaluacion.es_correcta(indice_pregunta, _opcion_de_boton[i], true):
			_botones_opcion[i].modulate = COLOR_BIEN
		elif i == numero_boton:
			_botones_opcion[i].modulate = COLOR_MAL
		else:
			_botones_opcion[i].modulate = Color(1, 1, 1, 0.45)
		_botones_opcion[i].focus_mode = Control.FOCUS_NONE
	boton.pivot_offset = boton.size / 2.0
	boton.scale = Vector2(1.1, 1.1)
	create_tween().tween_property(boton, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

	var explicacion := str(Evaluacion.PREGUNTAS_FINAL[indice_pregunta]["explicacion"])
	_aviso.text = ("¡Correcto! " if correcta else "Casi... ") + explicacion
	_aviso.add_theme_font_size_override("font_size", 7)
	_aviso.add_theme_color_override("font_color", COLOR_BIEN if correcta else COLOR_MAL)
	_aviso.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var fila := _fila_botones()
	var siguiente := _boton("Siguiente (Enter)", fila)
	siguiente.pressed.connect(_siguiente_pregunta)
	siguiente.grab_focus()


func _siguiente_pregunta() -> void:
	_paso += 1
	if _paso < _orden.size():
		_mostrar_pregunta()
		return
	var segundos := (Time.get_ticks_msec() - _tiempo_inicio) / 1000.0
	if es_final():
		_indice_registro = Evaluacion.guardar_final(respuestas, segundos)
		_mostrar_encuesta()
	else:
		Evaluacion.guardar_inicial(nombre, respuestas, segundos)
		_mostrar_listo()


# ================================================================= ENCUESTA (sólo trivia final)
func _mostrar_encuesta() -> void:
	fase = Fase.ENCUESTA
	_limpiar()
	_titulo("¿QUÉ TE PARECIÓ EL JUEGO?")
	_texto("1 = nada   ·   5 = mucho", 6, COLOR_SUAVE)
	valores_encuesta.resize(Evaluacion.ENCUESTA.size())
	valores_encuesta.fill(0)
	var primero: Button = null
	for i in Evaluacion.ENCUESTA.size():
		var fila := HBoxContainer.new()
		contenido.add_child(fila)
		var pregunta := _texto(str(Evaluacion.ENCUESTA[i]["texto"]), 7, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, fila)
		pregunta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pregunta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var escala := HBoxContainer.new()
		escala.add_theme_constant_override("separation", 2)
		fila.add_child(escala)
		for valor in range(1, 6):
			var boton := _boton(str(valor), escala)
			boton.custom_minimum_size = Vector2(16, 14)
			boton.add_theme_font_size_override("font_size", 8)
			boton.pressed.connect(_elegir_valor.bind(i, valor, escala))
			if primero == null:
				primero = boton
	_espacio(2)
	_aviso = _texto("", 7, COLOR_MAL)
	var botones := _fila_botones()
	var ver := _boton("Ver mis resultados", botones)
	ver.pressed.connect(_terminar_encuesta)
	primero.grab_focus()


func _elegir_valor(item: int, valor: int, escala: HBoxContainer) -> void:
	valores_encuesta[item] = valor
	Sonido.reproducir("boton", false)
	for i in escala.get_child_count():
		escala.get_child(i).modulate = COLOR_ELEGIDO if i < valor else Color.WHITE


func _terminar_encuesta() -> void:
	if valores_encuesta.has(0):
		_aviso.text = "Responde las %d preguntas, por favor" % Evaluacion.ENCUESTA.size()
		Sonido.reproducir("error", false)
		return
	Evaluacion.guardar_encuesta(_indice_registro, valores_encuesta)
	_mostrar_comparacion()


# ================================================================= RESULTADOS
## Al terminar la trivia inicial.
func _mostrar_listo() -> void:
	fase = Fase.RESULTADO
	_limpiar()
	_titulo("¡LISTO, %s!" % nombre.to_upper())
	var aciertos := Evaluacion.aciertos(respuestas, false)
	_texto("Acertaste %d de %d preguntas." % [aciertos, Evaluacion.total_preguntas()], 9)
	_espacio(4)
	_texto("Ahora juega y aprende a separar los residuos en la caneca correcta. "
		+ "Cuando termines una partida podrás hacer la TRIVIA FINAL y ver cuánto mejoraste.", 7, COLOR_SUAVE)
	_espacio(6)
	var botones := _fila_botones()
	var jugar := _boton("¡A limpiar el río!", botones)
	jugar.pressed.connect(_ir_al_juego)
	jugar.grab_focus()


## Al terminar la trivia final y la encuesta: antes vs. después.
func _mostrar_comparacion() -> void:
	fase = Fase.RESULTADO
	_limpiar()
	var registro: Dictionary = Evaluacion.registros[_indice_registro]
	var total := Evaluacion.total_preguntas()
	var antes := Evaluacion.aciertos(registro["inicial"], false)
	var despues := Evaluacion.aciertos(respuestas, true)
	var mejora := despues - antes

	_titulo("TU AVANCE, %s" % nombre.to_upper())
	contenido.add_child(_fila_comparacion("Antes de jugar", antes, total, Color(0.6, 0.65, 0.7)))
	contenido.add_child(_fila_comparacion("Después de jugar", despues, total, COLOR_BIEN))

	var mensaje := ""
	if mejora > 0:
		mensaje = "¡Mejoraste %d respuesta%s! El río te lo agradece." % [mejora, "" if mejora == 1 else "s"]
		Sonido.reproducir("victoria", false)
	elif despues == total:
		mensaje = "¡Perfecto en las dos trivias! Eres un EcoGuardián experto."
		Sonido.reproducir("victoria", false)
	elif mejora == 0:
		mensaje = "Quedaste igual. ¡Juega otra vez y fíjate en los avisos de las canecas!"
	else:
		mensaje = "Esta vez acertaste menos. Repasa la sección \"Cómo jugar\" y vuelve a intentarlo."
	_texto(mensaje, 8, COLOR_TITULO)

	# Qué repasar: las preguntas que falló en la trivia final
	var fallos: Array[String] = []
	for i in total:
		if not Evaluacion.es_correcta(i, respuestas[i], true):
			fallos.append(str(Evaluacion.TEMAS[i]).to_lower())
	if fallos.is_empty():
		_texto("Respondiste todo bien en la trivia final.", 7, COLOR_SUAVE)
	else:
		_texto("Para repasar: " + ", ".join(fallos), 7, COLOR_SUAVE)

	_espacio(2)
	var botones := _fila_botones()
	var menu := _boton("Menú principal", botones)
	menu.pressed.connect(_ir_al_menu)
	menu.grab_focus()


func _fila_comparacion(texto: String, valor: int, total: int, color: Color) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	var etiqueta := _texto(texto, 8, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, fila)
	etiqueta.custom_minimum_size = Vector2(80, 0)
	var barra := _barra(0.0, color, 9)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(barra)
	var numero := _texto("%d/%d" % [valor, total], 8, color, HORIZONTAL_ALIGNMENT_LEFT, fila)
	numero.custom_minimum_size = Vector2(28, 0)
	# La barra se llena con un Tween
	var relleno := barra.get_child(0) as ColorRect
	create_tween().tween_method(func(p: float): relleno.anchor_right = p, 0.0, float(valor) / total, 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return fila


# ================================================================= AYUDAS DE INTERFAZ
func _limpiar() -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()


func _titulo(texto: String) -> Label:
	var etiqueta := _texto(texto, 12, COLOR_TITULO)
	etiqueta.add_theme_constant_override("outline_size", 3)
	return etiqueta


func _texto(texto: String, tamano: int, color := Color.WHITE,
		alineacion := HORIZONTAL_ALIGNMENT_CENTER, padre: Node = null) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = alineacion
	# Sólo los textos que ocupan todo el ancho hacen salto de línea automático.
	# Dentro de una fila (HBox) una etiqueta con autowrap y sin ancho mínimo
	# se encoge a una letra por línea, así que ahí se activa a mano.
	if padre == null:
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	(padre if padre != null else contenido).add_child(etiqueta)
	return etiqueta


func _boton(texto: String, padre: Node) -> Button:
	var boton := Button.new()
	boton.text = texto
	padre.add_child(boton)
	return boton


func _fila_botones() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	contenido.add_child(fila)
	return fila


func _espacio(alto: int) -> void:
	var separador := Control.new()
	separador.custom_minimum_size = Vector2(0, alto)
	contenido.add_child(separador)


## Barra simple hecha con dos ColorRect (fondo + relleno con ancla derecha = proporción).
func _barra(proporcion: float, color: Color, alto: int) -> ColorRect:
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.06, 0.07, 0.9)
	fondo.custom_minimum_size = Vector2(0, alto)
	var relleno := ColorRect.new()
	relleno.color = color
	relleno.anchor_bottom = 1.0
	relleno.anchor_right = proporcion
	fondo.add_child(relleno)
	return fondo


func _barra_avance(proporcion: float) -> ColorRect:
	return _barra(proporcion, COLOR_TITULO, 2)


func _ir_al_juego() -> void:
	Sonido.reproducir("boton", false)
	Guardado.nivel_actual = 1  # Después de la trivia inicial siempre se empieza por el nivel 1
	Transicion.cambiar_escena(RUTA_JUEGO)


func _ir_al_menu() -> void:
	Sonido.reproducir("boton", false)
	Transicion.cambiar_escena(RUTA_MENU)
