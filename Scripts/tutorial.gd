class_name Tutorial
extends CanvasLayer
## Tutorial corto al inicio del nivel 1 (4 pasos). Mientras dura, no aparece
## basura nueva ni enemigos y la contaminación no sube (ver juego.gd).
##   1. Moverse   2. Recoger un residuo   3. Depositarlo en su caneca   4. Disparar
## Una flecha que rebota señala el residuo y la caneca correcta.
## Enter salta el tutorial en cualquier momento.

signal terminado

enum Paso { MOVER, RECOGER, DEPOSITAR, DISPARAR, LISTO }

const COLOR_TEXTO := Color(1.0, 0.95, 0.75)
## Residuo de práctica: la cáscara de banano (va en la caneca verde)
const INDICE_RESIDUO := 5

var juego: Node2D   ## lo asigna juego.gd antes de agregar el tutorial

var _paso := Paso.MOVER
var _inicio := Vector2.ZERO
var _residuo: Residuo = null
var _datos_residuo: Dictionary = {}
var _flecha: Flecha
var _cerrado := false

@onready var texto: Label = $Panel/Texto
@onready var contador: Label = $Panel/Contador
@onready var panel: Panel = $Panel


func _ready() -> void:
	var jugador: Jugador = juego.jugador
	_inicio = jugador.global_position
	_datos_residuo = Reciclaje.RESIDUOS[INDICE_RESIDUO]
	jugador.mochila_cambiada.connect(_on_mochila_cambiada)
	for caneca in get_tree().get_nodes_in_group("canecas"):
		caneca.residuo_depositado.connect(_on_residuo_depositado)
	_flecha = Flecha.new()
	juego.mapa.add_child(_flecha)
	_flecha.visible = false
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.4)
	_mostrar_paso(Paso.MOVER)


func _process(_delta: float) -> void:
	if _paso == Paso.MOVER and juego.jugador.global_position.distance_to(_inicio) > 28.0:
		_mostrar_paso(Paso.RECOGER)
	# La flecha sigue al residuo (por si el imán o algo lo mueve)
	if _paso == Paso.RECOGER and is_instance_valid(_residuo):
		_flecha.global_position = _residuo.global_position + Vector2(0, -16)


func _input(event: InputEvent) -> void:
	if _cerrado:
		return
	if event.is_action_pressed("saltar"):
		get_viewport().set_input_as_handled()
		_terminar()
	elif _paso == Paso.DISPARAR and event.is_action_pressed("disparar"):
		_mostrar_paso(Paso.LISTO)


func _mostrar_paso(paso: Paso) -> void:
	_paso = paso
	contador.text = "Tutorial %d/4   ·   Enter: saltar" % mini(int(paso) + 1, 4)
	_flecha.visible = false
	match paso:
		Paso.MOVER:
			texto.text = "¡Hola, EcoGuardián! Muévete con W A S D o con las flechas"
		Paso.RECOGER:
			texto.text = "Camina sobre la basura para guardarla en tu mochila"
			if not is_instance_valid(_residuo):
				_residuo = juego.soltar_residuo(_datos_residuo, juego.jugador.global_position, 40.0, 72.0)
			_flecha.visible = _residuo != null
		Paso.DEPOSITAR:
			var tipo: int = _datos_residuo["caneca"]
			texto.text = "La %s es orgánica: llévala a la caneca %s y pulsa E" % [
				str(_datos_residuo["nombre"]).to_lower(), Reciclaje.nombre_caneca(tipo)]
			for caneca in get_tree().get_nodes_in_group("canecas"):
				if caneca.tipo == tipo:
					_flecha.global_position = caneca.global_position + Vector2(0, -30)
					_flecha.visible = true
		Paso.DISPARAR:
			texto.text = "Las manchas de petróleo te persiguen. Dispara burbujas con ESPACIO o clic"
		Paso.LISTO:
			texto.text = "¡Muy bien! Recicla %d residuos antes de que la contaminación llegue a 100 %%" % juego.meta_reciclados
			contador.text = "¡A jugar!"
			var espera := create_tween()
			espera.tween_interval(2.8)
			espera.tween_callback(_terminar)
	# Pequeño rebote del panel en cada paso
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(1.06, 1.06)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.2)
	if paso != Paso.MOVER:
		Sonido.reproducir("boton", false)


func _on_mochila_cambiada(contenido: Array, _seleccion: int) -> void:
	if _paso == Paso.RECOGER and not contenido.is_empty():
		_mostrar_paso(Paso.DEPOSITAR)


func _on_residuo_depositado(_residuo_depositado: Dictionary, correcto: bool, _caneca: Caneca) -> void:
	if _paso != Paso.DEPOSITAR:
		return
	if correcto:
		_mostrar_paso(Paso.DISPARAR)
	else:
		# Se equivocó: el juego ya le dijo cuál era la caneca. Se repite con otro residuo.
		_residuo = null
		_mostrar_paso(Paso.RECOGER)


func _terminar() -> void:
	if _cerrado:
		return
	_cerrado = true
	if is_instance_valid(_flecha):
		_flecha.queue_free()
	var salida := create_tween()
	salida.tween_property(panel, "modulate:a", 0.0, 0.3)
	salida.tween_callback(queue_free)
	terminado.emit()


## Flecha amarilla que rebota sobre el objetivo (se dibuja en el mundo).
class Flecha extends Node2D:
	var _tiempo := 0.0

	func _ready() -> void:
		z_index = 20

	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()

	func _draw() -> void:
		var y := sin(_tiempo * 6.0) * 3.0
		var puntos := PackedVector2Array([Vector2(-6, -8 + y), Vector2(6, -8 + y), Vector2(0, 0 + y)])
		var borde := PackedVector2Array([Vector2(-8, -9 + y), Vector2(8, -9 + y), Vector2(0, 2 + y)])
		draw_colored_polygon(borde, Color(0.11, 0.09, 0.15))
		draw_colored_polygon(puntos, Color(1.0, 0.86, 0.3))
