class_name Mancha
extends CharacterBody2D
## Enemigo "mancha de petróleo".
## - Deambula despacio y, si ve al jugador, lo persigue.
## - Al tocarlo le quita vida y lo frena (lo dice el documento del proyecto).
## - Se derrota con 2 burbujas de jabón. A veces suelta un power-up imán.

signal derrotada(mancha: Mancha)

@export var velocidad := 22.0
@export var velocidad_persecucion := 36.0
@export var radio_deteccion := 110.0
@export var vida := 2
@export_range(0.0, 1.0) var probabilidad_iman := 0.4
@export var escena_iman: PackedScene

var _direccion := Vector2.ZERO
var _empuje := Vector2.ZERO
var _derrotada := false
var _jugador_tocando: Jugador = null

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var zona_contacto: Area2D = $ZonaContacto
@onready var temporizador_rumbo: Timer = $TemporizadorRumbo


func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("manchas")
	zona_contacto.body_entered.connect(_on_contacto_entered)
	zona_contacto.body_exited.connect(_on_contacto_exited)
	temporizador_rumbo.timeout.connect(_nuevo_rumbo)
	_nuevo_rumbo()
	sprite.play("mover")
	# Brota del suelo
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if _derrotada:
		return
	var jugador := get_tree().get_first_node_in_group("jugador") as Jugador
	var persiguiendo := jugador != null and jugador.activo \
		and global_position.distance_to(jugador.global_position) < radio_deteccion
	if persiguiendo:
		_direccion = global_position.direction_to(jugador.global_position)
		velocity = _direccion * velocidad_persecucion
	else:
		velocity = _direccion * velocidad
	velocity += _empuje
	_empuje = _empuje.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()

	# Si choca con algo mientras deambula, cambia de rumbo
	if not persiguiendo and get_slide_collision_count() > 0:
		_nuevo_rumbo()
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	# Daño continuo mientras toca al jugador (el jugador tiene invulnerabilidad temporal)
	if _jugador_tocando != null:
		_jugador_tocando.recibir_dano(1, global_position)


func _nuevo_rumbo() -> void:
	# A veces se queda quieta, a veces elige una dirección al azar
	if randf() < 0.25:
		_direccion = Vector2.ZERO
	else:
		_direccion = Vector2.RIGHT.rotated(randf() * TAU)
	temporizador_rumbo.start(randf_range(1.5, 3.0))


## La llaman las burbujas al chocar.
func recibir_golpe(direccion_golpe: Vector2) -> void:
	if _derrotada:
		return
	vida -= 1
	_empuje = direccion_golpe * 150.0
	Sonido.reproducir("golpe")
	# Destello blanco y aplastamiento
	sprite.play("golpe")
	sprite.scale = Vector2(1.4, 0.7)
	var golpe := create_tween()
	golpe.tween_property(sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	golpe.tween_callback(sprite.play.bind("mover"))
	if vida <= 0:
		_derrotar()


func _derrotar() -> void:
	_derrotada = true
	remove_from_group("enemigos")
	remove_from_group("manchas")
	collision_layer = 0
	zona_contacto.set_deferred("monitoring", false)
	if _jugador_tocando != null:
		_jugador_tocando.salir_de_mancha()
		_jugador_tocando = null
	Sonido.reproducir("mancha_derrotada")
	derrotada.emit(self)
	if escena_iman != null and randf() < probabilidad_iman:
		_soltar_iman.call_deferred()
	var desaparecer := create_tween().set_parallel()
	desaparecer.tween_property(self, "scale", Vector2(1.8, 0.2), 0.35)
	desaparecer.tween_property(self, "modulate:a", 0.0, 0.35)
	desaparecer.chain().tween_callback(queue_free)


func _soltar_iman() -> void:
	var iman := escena_iman.instantiate()
	iman.position = position
	get_parent().add_child(iman)


func _on_contacto_entered(body: Node2D) -> void:
	if body is Jugador and not _derrotada:
		_jugador_tocando = body
		body.entrar_en_mancha()
		body.recibir_dano(1, global_position)


func _on_contacto_exited(body: Node2D) -> void:
	if body == _jugador_tocando:
		_jugador_tocando.salir_de_mancha()
		_jugador_tocando = null
