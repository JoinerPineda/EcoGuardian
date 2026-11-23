class_name Jugador
extends CharacterBody2D
## El EcoGuardián.
## - Se mueve en 4 direcciones (como en el Zelda original): si se presionan
##   dos ejes a la vez, manda la última tecla presionada.
## - Recoge residuos al tocarlos y los guarda en una mochila de 3 espacios.
## - Deposita el residuo seleccionado en la caneca cercana con la tecla E.
## - Dispara burbujas de jabón (Espacio o clic) contra las manchas de petróleo.

# ---------------------------------------------------------------- señales propias
signal mochila_cambiada(contenido: Array, seleccion: int)
signal vida_cambiada(vida: int, vida_maxima: int)
signal iman_cambiado(activo: bool)
signal caneca_cercana_cambiada(caneca: Caneca)
signal mensaje(texto: String, color: Color)
signal murio

const CAPACIDAD_MOCHILA := 3
const COLOR_AVISO := Color(1.0, 0.85, 0.4)
enum Eje { HORIZONTAL, VERTICAL }

# ---------------------------------------------------------------- parámetros editables
@export var velocidad := 80.0
@export var vida_maxima := 3
@export var tiempo_invulnerable := 1.2
@export_range(0.1, 1.0) var factor_lentitud_mancha := 0.5
@export var radio_iman := 140.0  ## alcance del imán (la pantalla mide 320 px de ancho)
@export var cadencia_disparo := 0.3
@export var escena_burbuja: PackedScene

# ---------------------------------------------------------------- estado
var vida := 3
var mochila: Array = []          # Lista de diccionarios del catálogo Reciclaje.RESIDUOS
var seleccion := 0               # Índice del residuo seleccionado en la mochila
var caneca_cercana: Caneca = null
var iman_activo := false
var activo := true               # Se desactiva al terminar la partida
var direccion_mirada := Vector2.DOWN

var _eje_preferido := Eje.HORIZONTAL
var _empuje := Vector2.ZERO
var _manchas_tocando := 0
var _invulnerable := false
var _puede_disparar := true
var _ultimo_aviso_ms := 0
var _avisado_iman_lleno := false

# ---------------------------------------------------------------- nodos
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camara: Camera2D = $Camara
@onready var temporizador_iman: Timer = $TemporizadorIman
@onready var temporizador_disparo: Timer = $TemporizadorDisparo
@onready var temporizador_invulnerable: Timer = $TemporizadorInvulnerable


func _ready() -> void:
	add_to_group("jugador")
	vida = vida_maxima
	sprite.play("quieto_abajo")


func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if activo:
		entrada = _leer_entrada_4_direcciones()
	var factor := factor_lentitud_mancha if _manchas_tocando > 0 else 1.0
	velocity = entrada * velocidad * factor + _empuje
	_empuje = _empuje.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()

	if entrada != Vector2.ZERO:
		direccion_mirada = entrada
	_actualizar_animacion(entrada)
	if iman_activo:
		queue_redraw()  # Redibuja el aura del imán (ver _draw)
		# Con la mochila llena el imán no puede atraer nada: se avisa una vez
		if not tiene_espacio() and not _avisado_iman_lleno:
			_avisado_iman_lleno = true
			mensaje.emit("Mochila llena: deposita para que el imán siga atrayendo", COLOR_AVISO)
		elif tiene_espacio():
			_avisado_iman_lleno = false


func _unhandled_input(event: InputEvent) -> void:
	if not activo:
		return
	if event.is_action_pressed("interactuar"):
		_depositar()
	elif event.is_action_pressed("disparar"):
		_disparar(event)
	elif event.is_action_pressed("siguiente_residuo"):
		cambiar_seleccion(seleccion + 1)
	elif event.is_action_pressed("ranura_1"):
		cambiar_seleccion(0)
	elif event.is_action_pressed("ranura_2"):
		cambiar_seleccion(1)
	elif event.is_action_pressed("ranura_3"):
		cambiar_seleccion(2)


# ================================================================= MOVIMIENTO
func _leer_entrada_4_direcciones() -> Vector2:
	# La última tecla presionada decide el eje cuando hay dos ejes activos
	if Input.is_action_just_pressed("mover_izquierda") or Input.is_action_just_pressed("mover_derecha"):
		_eje_preferido = Eje.HORIZONTAL
	elif Input.is_action_just_pressed("mover_arriba") or Input.is_action_just_pressed("mover_abajo"):
		_eje_preferido = Eje.VERTICAL

	var x := Input.get_axis("mover_izquierda", "mover_derecha")
	var y := Input.get_axis("mover_arriba", "mover_abajo")
	if x != 0.0 and y != 0.0:
		if _eje_preferido == Eje.HORIZONTAL:
			y = 0.0
		else:
			x = 0.0
	return Vector2(signf(x), signf(y))


func _actualizar_animacion(entrada: Vector2) -> void:
	var prefijo := "caminar_" if entrada != Vector2.ZERO else "quieto_"
	var animacion := prefijo + _nombre_direccion(direccion_mirada)
	if sprite.animation != animacion:
		sprite.play(animacion)


func _nombre_direccion(direccion: Vector2) -> String:
	if absf(direccion.x) > absf(direccion.y):
		return "derecha" if direccion.x > 0.0 else "izquierda"
	return "abajo" if direccion.y > 0.0 else "arriba"


# ================================================================= MOCHILA
func tiene_espacio() -> bool:
	return mochila.size() < CAPACIDAD_MOCHILA


## Lo llaman los residuos al ser tocados. Devuelve true si se pudo guardar.
func intentar_recoger(datos: Dictionary) -> bool:
	if not activo:
		return false
	if not tiene_espacio():
		_avisar("¡Mochila llena! Lleva los residuos a las canecas", "lleno")
		return false
	mochila.append(datos)
	if mochila.size() == 1:
		seleccion = 0
	mochila_cambiada.emit(mochila, seleccion)
	Sonido.reproducir("recoger")
	return true


## La bolsa voladora le quita al jugador el residuo seleccionado.
## Devuelve el residuo quitado o un Dictionary vacío si la mochila está vacía.
func quitar_residuo() -> Dictionary:
	if mochila.is_empty():
		return {}
	var residuo: Dictionary = mochila.pop_at(seleccion)
	seleccion = clampi(seleccion, 0, maxi(mochila.size() - 1, 0))
	mochila_cambiada.emit(mochila, seleccion)
	return residuo


func cambiar_seleccion(indice: int) -> void:
	if mochila.is_empty():
		return
	seleccion = wrapi(indice, 0, mochila.size())
	mochila_cambiada.emit(mochila, seleccion)
	Sonido.reproducir("boton", false)


func _depositar() -> void:
	if caneca_cercana == null:
		_avisar("Acércate a una caneca para depositar")
		return
	if mochila.is_empty():
		_avisar("Tu mochila está vacía")
		return
	var residuo: Dictionary = mochila.pop_at(seleccion)
	seleccion = clampi(seleccion, 0, maxi(mochila.size() - 1, 0))
	mochila_cambiada.emit(mochila, seleccion)
	caneca_cercana.recibir_residuo(residuo)


## Las canecas avisan cuando el jugador entra o sale de su zona.
func establecer_caneca_cercana(caneca: Caneca) -> void:
	caneca_cercana = caneca
	caneca_cercana_cambiada.emit(caneca)


func salir_de_caneca(caneca: Caneca) -> void:
	if caneca_cercana == caneca:
		establecer_caneca_cercana(null)


## Muestra un aviso en el HUD sin repetirlo muchas veces seguidas.
func _avisar(texto: String, sonido := "") -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_aviso_ms < 900:
		return
	_ultimo_aviso_ms = ahora
	mensaje.emit(texto, COLOR_AVISO)
	if sonido != "":
		Sonido.reproducir(sonido)


# ================================================================= BURBUJAS
func _disparar(event: InputEvent) -> void:
	if not _puede_disparar or escena_burbuja == null:
		return
	var direccion := direccion_mirada
	if event is InputEventMouseButton:
		# Con el ratón se dispara hacia el puntero
		direccion = global_position.direction_to(get_global_mouse_position())
		if direccion == Vector2.ZERO:
			direccion = direccion_mirada
	var burbuja := escena_burbuja.instantiate() as Burbuja
	burbuja.direccion = direccion
	get_parent().add_child(burbuja)
	burbuja.global_position = global_position + Vector2(0, -7) + direccion * 8.0
	_puede_disparar = false
	temporizador_disparo.start(cadencia_disparo)
	Sonido.reproducir("burbuja")


func _on_temporizador_disparo_timeout() -> void:
	_puede_disparar = true


# ================================================================= DAÑO
func recibir_dano(cantidad: int, origen: Vector2) -> void:
	if _invulnerable or not activo:
		return
	vida = maxi(vida - cantidad, 0)
	vida_cambiada.emit(vida, vida_maxima)
	Sonido.reproducir("dano")
	_empuje = origen.direction_to(global_position) * 190.0
	_sacudir_camara()
	if vida <= 0:
		murio.emit()
		return
	# Parpadeo de invulnerabilidad con un Tween
	_invulnerable = true
	temporizador_invulnerable.start(tiempo_invulnerable)
	var parpadeo := create_tween().set_loops(int(tiempo_invulnerable / 0.2))
	parpadeo.tween_property(sprite, "modulate:a", 0.25, 0.1)
	parpadeo.tween_property(sprite, "modulate:a", 1.0, 0.1)


func _on_temporizador_invulnerable_timeout() -> void:
	_invulnerable = false
	sprite.modulate.a = 1.0


func _sacudir_camara() -> void:
	var sacudida := create_tween()
	for i in 4:
		sacudida.tween_property(camara, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.04)
	sacudida.tween_property(camara, "offset", Vector2.ZERO, 0.04)


## Las manchas de petróleo frenan al jugador mientras lo tocan.
func entrar_en_mancha() -> void:
	_manchas_tocando += 1
	sprite.self_modulate = Color(0.65, 0.6, 0.8)


func salir_de_mancha() -> void:
	_manchas_tocando = maxi(_manchas_tocando - 1, 0)
	if _manchas_tocando == 0:
		sprite.self_modulate = Color.WHITE


# ================================================================= IMÁN
func activar_iman(duracion: float) -> void:
	iman_activo = true
	_avisado_iman_lleno = false
	temporizador_iman.start(duracion)
	iman_cambiado.emit(true)
	Sonido.reproducir("iman")


func tiempo_iman_restante() -> float:
	return temporizador_iman.time_left


func _on_temporizador_iman_timeout() -> void:
	iman_activo = false
	iman_cambiado.emit(false)
	queue_redraw()


## Dibuja un aura pulsante alrededor del jugador mientras el imán está activo.
func _draw() -> void:
	if not iman_activo:
		return
	var pulso := 0.8 + 0.2 * sin(Time.get_ticks_msec() / 120.0)
	draw_arc(Vector2(0, -6), radio_iman * pulso, 0.0, TAU, 40, Color(1.0, 0.35, 0.35, 0.35), 1.0)
	draw_arc(Vector2(0, -6), 12.0 + 3.0 * pulso, 0.0, TAU, 16, Color(1.0, 0.8, 0.8, 0.6), 1.0)
