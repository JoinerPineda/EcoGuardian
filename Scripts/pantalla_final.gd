class_name PantallaFinal
extends CanvasLayer
## Pantalla de victoria o derrota con estrellas, estadísticas, récord
## y un dato educativo. Enter / R reinicia, Esc vuelve al menú.
## Si el participante tiene pendiente la trivia final, aparece el botón "Trivia final".
## Al ganar un nivel que no es el último aparece "Siguiente nivel".

const RUTA_MENU := "res://Escenas/MenuPrincipal.tscn"
const RUTA_TRIVIA := "res://Escenas/Interfaz/Trivia.tscn"

@export var textura_estrella_llena: Texture2D
@export var textura_estrella_vacia: Texture2D

var _activa := false

@onready var titulo: Label = $Panel/Contenido/Titulo
@onready var motivo: Label = $Panel/Contenido/Motivo
@onready var estrellas: Array[TextureRect] = [
	$Panel/Contenido/Estrellas/Estrella1, $Panel/Contenido/Estrellas/Estrella2, $Panel/Contenido/Estrellas/Estrella3]
@onready var estadisticas: Label = $Panel/Contenido/Estadisticas
@onready var record: Label = $Panel/Contenido/Record
@onready var dato: Label = $Panel/Contenido/Dato
@onready var boton_reiniciar: Button = $Panel/Contenido/Botones/Reiniciar
@onready var boton_menu: Button = $Panel/Contenido/Botones/Menu
@onready var boton_trivia: Button = $Panel/Contenido/Botones/TriviaFinal
@onready var boton_siguiente: Button = $Panel/Contenido/Botones/Siguiente
@onready var panel: Panel = $Panel


func _ready() -> void:
	visible = false
	boton_reiniciar.pressed.connect(_reiniciar)
	boton_menu.pressed.connect(_ir_al_menu)
	boton_trivia.pressed.connect(_ir_a_trivia_final)
	boton_siguiente.pressed.connect(_siguiente_nivel)


func mostrar(resumen: Dictionary) -> void:
	_activa = true
	visible = true
	var gano: bool = resumen["gano"]
	titulo.text = "¡RÍO LIMPIO!" if gano else "EL RÍO SIGUE SUCIO"
	if gano and not resumen["hay_siguiente"] and resumen["nivel"] > 1:
		titulo.text = "¡ERES UN ECOGUARDIÁN!"
	titulo.modulate = Color(0.55, 1.0, 0.6) if gano else Color(1.0, 0.5, 0.45)
	motivo.text = resumen["motivo"]
	var minutos := floori(resumen["tiempo"] / 60.0)
	var segundos := int(resumen["tiempo"]) % 60
	estadisticas.text = "Puntaje: %d     Reciclados: %d/%d\nPrecisión: %d%%     Contaminación final: %d%%\nTiempo: %d:%02d" % [
		resumen["puntaje"], resumen["reciclados"], resumen["meta"],
		roundi(resumen["precision"] * 100.0), roundi(resumen["contaminacion"]), minutos, segundos]
	if resumen["nuevo_record"]:
		record.text = "¡NUEVO RÉCORD! %d puntos" % resumen["mejor_puntaje"]
		record.modulate = Color(1.0, 0.85, 0.3)
	else:
		record.text = "Mejor puntaje: %d" % resumen["mejor_puntaje"]
		record.modulate = Color.WHITE
	dato.text = "Sabías que... " + str(resumen["dato"])

	# Entrada del panel y estrellas una por una (Tweens)
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var entrada := create_tween().set_parallel()
	entrada.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada.tween_property(panel, "modulate:a", 1.0, 0.2)
	var cantidad: int = resumen["estrellas"]
	for i in estrellas.size():
		var estrella := estrellas[i]
		estrella.texture = textura_estrella_llena if i < cantidad else textura_estrella_vacia
		estrella.pivot_offset = Vector2(8, 8)
		estrella.scale = Vector2.ZERO
		var aparicion := create_tween()
		aparicion.tween_interval(0.35 + i * 0.25)
		aparicion.tween_property(estrella, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < cantidad:
			aparicion.tween_callback(Sonido.reproducir.bind("acierto", false))
	# Botones: siguiente nivel (si ganó), trivia final (si está pendiente),
	# jugar de nuevo y menú. Caben máximo tres, así que "Jugar de nuevo" se
	# esconde cuando están los otros dos (la tecla R sigue funcionando).
	boton_siguiente.visible = resumen["hay_siguiente"]
	boton_siguiente.text = "Nivel %d (Enter)" % (resumen["nivel"] + 1)
	boton_trivia.visible = Evaluacion.trivia_final_pendiente()
	boton_reiniciar.visible = not (boton_siguiente.visible and boton_trivia.visible)
	boton_reiniciar.text = "Jugar de nuevo (R)" if boton_trivia.visible or boton_siguiente.visible else "Jugar de nuevo (Enter/R)"
	if boton_siguiente.visible:
		boton_siguiente.grab_focus()
	elif boton_trivia.visible:
		boton_trivia.grab_focus()
	else:
		boton_reiniciar.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not _activa:
		return
	if event.is_action_pressed("reiniciar") and event is InputEventKey and event.physical_keycode == KEY_R:
		_reiniciar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reiniciar"):
		# Enter activa el botón que tenga el foco
		var enfocado := get_viewport().gui_get_focus_owner() as Button
		if enfocado != null and enfocado.is_visible_in_tree():
			enfocado.pressed.emit()
		else:
			_reiniciar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pausa"):
		_ir_al_menu()
		get_viewport().set_input_as_handled()


func _reiniciar() -> void:
	if not _activa:
		return
	_activa = false
	Transicion.reiniciar()


func _siguiente_nivel() -> void:
	if not _activa:
		return
	_activa = false
	Sonido.reproducir("boton", false)
	Guardado.nivel_actual += 1
	Transicion.reiniciar()


func _ir_a_trivia_final() -> void:
	if not _activa:
		return
	_activa = false
	Sonido.reproducir("boton", false)
	Evaluacion.modo = Evaluacion.Modo.FINAL
	Transicion.cambiar_escena(RUTA_TRIVIA)


func _ir_al_menu() -> void:
	if not _activa:
		return
	_activa = false
	Transicion.cambiar_escena(RUTA_MENU)
