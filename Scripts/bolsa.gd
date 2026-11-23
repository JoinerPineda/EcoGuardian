class_name Bolsa
extends CharacterBody2D
## Enemigo del nivel 2: bolsa plástica que el viento arrastra.
## - Vuela con un vaivén y pasa por encima del agua y de los obstáculos.
## - Si ve al jugador lo sigue. Al tocarlo le QUITA el residuo seleccionado
##   (cae al suelo cerca) y se aleja volando. Si la mochila está vacía, quita vida.
##   En los dos casos la contaminación sube (lo hace juego.gd con la señal "robo").
## - Se atrapa con 2 burbujas: cae al suelo como "Bolsa plástica" para reciclar
##   en la caneca blanca (eso lo hace juego.gd al recibir la señal "derrotada").

signal derrotada(bolsa: Node2D)
## residuo vacío = no había nada que quitar (el jugador perdió una vida)
signal robo(residuo: Dictionary, posicion: Vector2)

@export var velocidad := 26.0
@export var velocidad_persecucion := 44.0   ## el jugador camina a 80: se puede escapar
@export var velocidad_huida := 75.0
@export var radio_deteccion := 120.0
@export var tiempo_huida := 2.5
@export var vida := 2

const ALTURA_VUELO := -14.0

var mapa: Mapa = null   ## lo asigna el generador de enemigos

var _viento := Vector2.RIGHT
var _tiempo := 0.0
var _huyendo := 0.0
var _golpeada := 0.0
var _empuje := Vector2.ZERO
var _derrotada := false
var _llegando := true

@onready var sprite: Sprite2D = $Sprite
@onready var sombra: Sprite2D = $Sombra
@onready var zona_contacto: Area2D = $ZonaContacto


func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("bolsas")
	zona_contacto.body_entered.connect(_on_contacto)
	_viento = Vector2.RIGHT.rotated(randf() * TAU)
	_tiempo = randf() * 10.0
	# Llega volando desde arriba
	sprite.position.y = ALTURA_VUELO - 60.0
	modulate.a = 0.0
	var llegada := create_tween().set_parallel()
	llegada.tween_property(sprite, "position:y", ALTURA_VUELO, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	llegada.tween_property(self, "modulate:a", 1.0, 0.4)
	llegada.chain().tween_callback(func(): _llegando = false)


func _physics_process(delta: float) -> void:
	if _derrotada:
		return
	_tiempo += delta
	_huyendo = maxf(_huyendo - delta, 0.0)
	_golpeada = maxf(_golpeada - delta, 0.0)

	var direccion := Vector2.ZERO
	var rapidez := velocidad
	var jugador := get_tree().get_first_node_in_group("jugador") as Jugador
	if jugador != null and jugador.activo:
		var hacia := global_position.direction_to(jugador.global_position)
		if _huyendo > 0.0:
			direccion = -hacia
			rapidez = velocidad_huida
		elif global_position.distance_to(jugador.global_position) < radio_deteccion:
			direccion = hacia
			rapidez = velocidad_persecucion
	if direccion == Vector2.ZERO:
		# Sin jugador cerca, el viento la lleva y cambia de rumbo poco a poco
		_viento = _viento.rotated(sin(_tiempo * 0.7) * delta * 1.2)
		direccion = _viento
	# Vaivén hacia los lados, como una bolsa movida por el viento
	var lado := direccion.orthogonal() * sin(_tiempo * 3.0) * 0.6
	velocity = (direccion + lado).normalized() * rapidez + _empuje
	_empuje = _empuje.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()
	_mantener_en_mapa()
	_animar()


func _animar() -> void:
	sprite.frame = 4 if _golpeada > 0.0 else int(_tiempo * 6.0) % 4
	if not _llegando:
		sprite.position.y = ALTURA_VUELO + sin(_tiempo * 2.5) * 3.0
	sprite.rotation = sin(_tiempo * 3.0) * 0.15
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	# La sombra se achica cuando la bolsa sube
	var altura := clampf(-sprite.position.y / 20.0, 0.5, 1.2)
	sombra.scale = Vector2.ONE * (1.3 - altura * 0.4)


## La bolsa no sale del mapa: si llega al borde, el viento la devuelve.
func _mantener_en_mapa() -> void:
	if mapa == null:
		return
	var limites := Rect2(mapa.rectangulo_en_pixeles()).grow(-24.0)
	if not limites.has_point(global_position):
		global_position = global_position.clamp(limites.position, limites.end)
		_viento = global_position.direction_to(limites.get_center())


func _on_contacto(body: Node2D) -> void:
	if _derrotada or _huyendo > 0.0 or not body is Jugador:
		return
	var jugador := body as Jugador
	var residuo := jugador.quitar_residuo()
	if residuo.is_empty():
		jugador.recibir_dano(1, global_position)
	else:
		Sonido.reproducir("escapa")
	robo.emit(residuo, jugador.global_position)
	_huyendo = tiempo_huida


## La llaman las burbujas al chocar.
func recibir_golpe(direccion_golpe: Vector2) -> void:
	if _derrotada:
		return
	vida -= 1
	_empuje = direccion_golpe * 160.0
	_golpeada = 0.2
	Sonido.reproducir("golpe")
	if vida <= 0:
		_derrotar()


func _derrotar() -> void:
	_derrotada = true
	remove_from_group("enemigos")
	remove_from_group("bolsas")
	collision_layer = 0
	zona_contacto.set_deferred("monitoring", false)
	sprite.frame = 4
	Sonido.reproducir("mancha_derrotada")
	derrotada.emit(self)
	# Cae al suelo dando vueltas y desaparece (en su lugar queda el residuo)
	var caida := create_tween().set_parallel()
	caida.tween_property(sprite, "position:y", -4.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	caida.tween_property(sprite, "rotation", TAU, 0.35)
	caida.tween_property(self, "modulate:a", 0.0, 0.35)
	caida.chain().tween_callback(queue_free)
