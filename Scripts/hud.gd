class_name HUD
extends CanvasLayer
## Interfaz durante la partida: vida, puntos, barra de contaminación,
## residuos reciclados, mochila, imán y mensajes.
## juego.gd conecta las señales del jugador y del juego a estas funciones.

@export var textura_corazon_lleno: Texture2D
@export var textura_corazon_vacio: Texture2D
@export var textura_residuos: Texture2D   ## Assets/residuos.png (15 cuadros de 16x16)
@export var estilo_ranura: StyleBox
@export var estilo_ranura_seleccionada: StyleBox

@onready var corazones: HBoxContainer = $BarraSuperior/Corazones
@onready var etiqueta_puntaje: Label = $BarraSuperior/Puntaje
@onready var barra_contaminacion: ProgressBar = $BarraSuperior/BarraContaminacion
@onready var etiqueta_contaminacion: Label = $BarraSuperior/PorcentajeContaminacion
@onready var etiqueta_reciclados: Label = $BarraSuperior/Reciclados
@onready var ranuras: Array[Panel] = [$Mochila/Ranura1, $Mochila/Ranura2, $Mochila/Ranura3]
@onready var nombre_seleccion: Label = $Mochila/NombreSeleccion
@onready var ayuda_caneca: Label = $AyudaCaneca
@onready var mensaje: Label = $Mensaje
@onready var combo: Label = $Combo
@onready var panel_iman: Control = $Iman
@onready var tiempo_iman: Label = $Iman/Tiempo

var _tween_mensaje: Tween
var _tween_barra: Tween
var _estilo_relleno: StyleBoxFlat


func _ready() -> void:
	mensaje.modulate.a = 0.0
	combo.visible = false
	panel_iman.visible = false
	ayuda_caneca.text = ""
	# Copia propia del estilo de relleno para poder cambiarle el color
	_estilo_relleno = (barra_contaminacion.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	barra_contaminacion.add_theme_stylebox_override("fill", _estilo_relleno)


func actualizar_puntaje(puntaje: int) -> void:
	etiqueta_puntaje.text = "Puntos %d" % puntaje
	_rebotar(etiqueta_puntaje)


func actualizar_reciclados(cantidad: int, meta: int) -> void:
	etiqueta_reciclados.text = "Reciclados %d/%d" % [cantidad, meta]
	_rebotar(etiqueta_reciclados)


func actualizar_vida(vida: int, vida_maxima: int) -> void:
	for i in corazones.get_child_count():
		var corazon := corazones.get_child(i) as TextureRect
		corazon.visible = i < vida_maxima
		corazon.texture = textura_corazon_lleno if i < vida else textura_corazon_vacio


func actualizar_contaminacion(porcentaje: float) -> void:
	# La barra se mueve suavemente con un Tween
	if _tween_barra:
		_tween_barra.kill()
	_tween_barra = create_tween()
	_tween_barra.tween_property(barra_contaminacion, "value", porcentaje, 0.2)
	etiqueta_contaminacion.text = "%d%%" % roundi(porcentaje)
	# Verde -> amarillo -> rojo
	var color := Color(0.35, 0.85, 0.4)
	if porcentaje >= 70.0:
		color = Color(0.95, 0.3, 0.25)
	elif porcentaje >= 40.0:
		color = Color(0.95, 0.75, 0.25)
	_estilo_relleno.bg_color = color
	# Parpadea cuando el peligro es alto
	var peligro := porcentaje >= 85.0 and int(Time.get_ticks_msec() / 250.0) % 2 == 0
	etiqueta_contaminacion.modulate = Color(1, 0.4, 0.4) if peligro else Color.WHITE


func actualizar_mochila(contenido: Array, seleccion: int) -> void:
	for i in ranuras.size():
		var ranura := ranuras[i]
		var icono := ranura.get_node("Icono") as TextureRect
		if i < contenido.size():
			var atlas := AtlasTexture.new()
			atlas.atlas = textura_residuos
			atlas.region = Rect2(contenido[i]["cuadro"] * 16, 0, 16, 16)
			icono.texture = atlas
		else:
			icono.texture = null
		var elegida := i == seleccion and i < contenido.size()
		ranura.add_theme_stylebox_override("panel", estilo_ranura_seleccionada if elegida else estilo_ranura)
	if contenido.is_empty():
		nombre_seleccion.text = "Mochila vacía"
	else:
		nombre_seleccion.text = "%s  (Q cambia)" % contenido[seleccion]["nombre"]


func mostrar_ayuda_caneca(caneca: Caneca) -> void:
	if caneca == null:
		ayuda_caneca.text = ""
		return
	ayuda_caneca.text = "Caneca %s: %s\n[E] depositar" % [
		Reciclaje.nombre_caneca(caneca.tipo), Reciclaje.descripcion_caneca(caneca.tipo)]
	ayuda_caneca.modulate = Reciclaje.COLOR_CANECA[caneca.tipo]


func mostrar_mensaje(texto: String, color := Color.WHITE) -> void:
	mensaje.text = texto
	mensaje.self_modulate = color
	if _tween_mensaje:
		_tween_mensaje.kill()
	mensaje.modulate.a = 1.0
	_tween_mensaje = create_tween()
	_tween_mensaje.tween_interval(2.2)
	_tween_mensaje.tween_property(mensaje, "modulate:a", 0.0, 0.5)


## Cartel grande al empezar el nivel ("NIVEL 2 / El pueblo").
func mostrar_titulo_nivel(titulo: String, nombre: String) -> void:
	var caja := VBoxContainer.new()
	caja.position = Vector2(0, 62)
	caja.size = Vector2(320, 40)
	caja.add_theme_constant_override("separation", -2)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caja)
	for datos in [[titulo, 9, Color(1.0, 0.86, 0.3)], [nombre, 18, Color(0.85, 1.0, 0.8)]]:
		var etiqueta := Label.new()
		etiqueta.text = datos[0]
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.add_theme_font_size_override("font_size", datos[1])
		etiqueta.add_theme_color_override("font_color", datos[2])
		etiqueta.add_theme_constant_override("outline_size", 4)
		etiqueta.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.06))
		caja.add_child(etiqueta)
	caja.modulate.a = 0.0
	var animacion := create_tween()
	animacion.tween_property(caja, "modulate:a", 1.0, 0.3)
	animacion.tween_interval(1.6)
	animacion.tween_property(caja, "modulate:a", 0.0, 0.5)
	animacion.tween_callback(caja.queue_free)


func mostrar_combo(racha: int) -> void:
	combo.text = "¡COMBO x%d!" % racha
	combo.visible = true
	combo.pivot_offset = combo.size / 2.0
	combo.scale = Vector2(0.3, 0.3)
	combo.modulate.a = 1.0
	var animacion := create_tween()
	animacion.tween_property(combo, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacion.tween_interval(0.6)
	animacion.tween_property(combo, "modulate:a", 0.0, 0.3)
	animacion.tween_callback(combo.hide)


func actualizar_iman(activo: bool) -> void:
	panel_iman.visible = activo
	if activo:
		mostrar_mensaje("¡Imán! Atrae la basura cercana, también la del río", Color(1, 0.6, 0.6))


func iman_visible() -> bool:
	return panel_iman.visible


func actualizar_tiempo_iman(segundos: float) -> void:
	tiempo_iman.text = "%.1fs" % segundos


func _rebotar(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(1.2, 1.2)
	create_tween().tween_property(control, "scale", Vector2.ONE, 0.15)
