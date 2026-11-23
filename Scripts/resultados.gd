class_name PantallaResultados
extends Control
## Pantalla para el docente: análisis de la trivia inicial vs. final de todo el grupo.
## - Promedios antes / después y porcentaje de participantes que mejoraron.
## - Gráfica de aciertos por pregunta (gris = antes, verde = después).
## - Temas a reforzar (menos de 60 % de aciertos en la trivia final).
## - Promedio de la encuesta de experiencia (1 a 5).
## Los datos completos quedan en user://evaluaciones.csv (botón "Abrir carpeta";
## en la versión web, botón "Descargar CSV").

const RUTA_MENU := "res://Escenas/MenuPrincipal.tscn"
const COLOR_TITULO := Color(1.0, 0.88, 0.4)
const COLOR_SUAVE := Color(0.75, 0.9, 0.85)
const COLOR_ANTES := Color(0.55, 0.6, 0.66)
const COLOR_DESPUES := Color(0.45, 0.9, 0.5)
const COLOR_ALERTA := Color(1.0, 0.55, 0.45)

var _confirmar_borrado := false

@onready var contenido: VBoxContainer = $Panel/Contenido


func _ready() -> void:
	_construir()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		_volver()


func _construir() -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()
	var datos := Evaluacion.resumen()
	var n: int = datos["completos"]

	_texto("RESULTADOS DE LA EVALUACIÓN", 10, COLOR_TITULO)
	var participantes := "Con las dos trivias: %d" % n
	if datos["solo_inicial"] > 0:
		participantes += "  ·  sólo inicial: %d" % datos["solo_inicial"]
	if n > 0:
		participantes += "  ·  barras: gris = antes de jugar, verde = después"
	_texto(participantes, 6, COLOR_SUAVE)

	if n == 0:
		_texto("\nTodavía no hay participantes que hayan hecho la trivia inicial y la final.\n\n"
			+ "Cada estudiante: Jugar -> trivia inicial -> partida -> trivia final.", 8)
	else:
		var antes: float = datos["promedio_inicial"]
		var despues: float = datos["promedio_final"]
		var diferencia := roundi((despues - antes) * 100.0)
		_texto("Promedio antes: %d %%   ->   después: %d %%   (%s%d puntos)   ·   mejoraron: %d %%" % [
			roundi(antes * 100.0), roundi(despues * 100.0), "+" if diferencia >= 0 else "",
			diferencia, roundi(datos["porcentaje_mejoraron"] * 100.0)], 7)
		_grafica(datos["por_pregunta"])
		_texto(_linea_encuesta(datos["encuesta"]), 6, COLOR_SUAVE)
		_texto(_linea_reforzar(datos["a_reforzar"]), 6, COLOR_ALERTA if not datos["a_reforzar"].is_empty() else COLOR_DESPUES)

	var relleno := Control.new()
	relleno.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.add_child(relleno)
	_botones()


## Una fila por pregunta: nombre corto, dos barras (antes / después) y porcentajes.
func _grafica(por_pregunta: Array) -> void:
	var tabla := GridContainer.new()
	tabla.columns = 3
	tabla.add_theme_constant_override("h_separation", 4)
	tabla.add_theme_constant_override("v_separation", 0)
	contenido.add_child(tabla)
	for i in por_pregunta.size():
		var pregunta: Dictionary = por_pregunta[i]
		var nombre := _texto("P%d %s" % [i + 1, pregunta["corto"]], 6, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, tabla)
		nombre.custom_minimum_size = Vector2(84, 0)
		var barras := VBoxContainer.new()
		barras.add_theme_constant_override("separation", 1)
		barras.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barras.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barras.add_child(_barra(pregunta["inicial"], COLOR_ANTES))
		barras.add_child(_barra(pregunta["final"], COLOR_DESPUES))
		tabla.add_child(barras)
		var porcentajes := _texto("%d -> %d %%" % [roundi(pregunta["inicial"] * 100.0), roundi(pregunta["final"] * 100.0)],
			6, COLOR_DESPUES if pregunta["final"] >= Evaluacion.UMBRAL_REFORZAR else COLOR_ALERTA, HORIZONTAL_ALIGNMENT_LEFT, tabla)
		porcentajes.custom_minimum_size = Vector2(46, 0)


func _linea_encuesta(promedios: Array) -> String:
	var partes: Array[String] = []
	for i in Evaluacion.ENCUESTA.size():
		partes.append("%s %.1f" % [Evaluacion.ENCUESTA[i]["corto"], promedios[i]])
	return "Encuesta (1-5):  " + "   ·   ".join(partes)


func _linea_reforzar(a_reforzar: Array) -> String:
	if a_reforzar.is_empty():
		return "Todas las preguntas superan el %d %% de aciertos en la trivia final." % roundi(Evaluacion.UMBRAL_REFORZAR * 100.0)
	var nombres: Array[String] = []
	for pregunta in a_reforzar.slice(0, 3):
		nombres.append("%s (%d %%)" % [pregunta["corto"], roundi(pregunta["final"] * 100.0)])
	return "A reforzar en clase: " + ", ".join(nombres)


func _botones() -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 6)
	contenido.add_child(fila)
	if OS.has_feature("web"):
		# En el navegador no hay carpetas: el CSV se descarga como un archivo
		var descargar := _boton("Descargar CSV", fila)
		descargar.pressed.connect(_descargar_csv)
	else:
		var abrir := _boton("Abrir carpeta (CSV)", fila)
		abrir.pressed.connect(_abrir_carpeta)
	var borrar := _boton("¿Seguro? Pulsa otra vez" if _confirmar_borrado else "Borrar datos", fila)
	if _confirmar_borrado:
		borrar.modulate = COLOR_ALERTA
	borrar.pressed.connect(_borrar)
	var volver := _boton("Volver (Esc)", fila)
	volver.pressed.connect(_volver)
	(borrar if _confirmar_borrado else volver).grab_focus()


func _abrir_carpeta() -> void:
	Sonido.reproducir("boton", false)
	Evaluacion.exportar_csv()
	OS.shell_open(Evaluacion.carpeta_datos())


## Versión web: el navegador descarga evaluaciones.csv a la carpeta de Descargas.
func _descargar_csv() -> void:
	Sonido.reproducir("boton", false)
	Evaluacion.exportar_csv()
	var datos := FileAccess.get_file_as_bytes(Evaluacion.RUTA_CSV)
	JavaScriptBridge.download_buffer(datos, "evaluaciones.csv", "text/csv")


func _borrar() -> void:
	Sonido.reproducir("boton", false)
	if _confirmar_borrado:
		Evaluacion.borrar_todo()
		_confirmar_borrado = false
	else:
		_confirmar_borrado = true
	_construir()


func _volver() -> void:
	Sonido.reproducir("boton", false)
	Transicion.cambiar_escena(RUTA_MENU)


# ================================================================= AYUDAS
func _texto(texto: String, tamano: int, color := Color.WHITE,
		alineacion := HORIZONTAL_ALIGNMENT_CENTER, padre: Node = null) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = alineacion
	if padre == null:  # en filas (Grid/HBox) el salto de línea encoge la etiqueta
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("line_spacing", -1)
	(padre if padre != null else contenido).add_child(etiqueta)
	return etiqueta


func _boton(texto: String, padre: Node) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.add_theme_font_size_override("font_size", 7)
	padre.add_child(boton)
	return boton


func _barra(proporcion: float, color: Color) -> ColorRect:
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.06, 0.07, 0.9)
	fondo.custom_minimum_size = Vector2(0, 3)
	var relleno := ColorRect.new()
	relleno.color = color
	relleno.anchor_bottom = 1.0
	relleno.anchor_right = clampf(proporcion, 0.0, 1.0)
	fondo.add_child(relleno)
	return fondo
