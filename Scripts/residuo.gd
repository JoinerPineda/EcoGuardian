class_name Residuo
extends Area2D
## Residuo tirado en el suelo. Se recoge al tocarlo (señal body_entered del Area2D).
## Si el jugador tiene el imán activo, el residuo se desliza hacia él.

signal recogido(datos: Dictionary)

## Velocidad con la que el imán atrae al residuo (píxeles por segundo)
@export var velocidad_atraccion := 200.0

var datos: Dictionary = {}   # Entrada del catálogo Reciclaje.RESIDUOS

var _jugador_encima: Jugador = null
var _recogido := false
var _tiempo := 0.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("residuos")
	if datos.is_empty():
		datos = Reciclaje.residuo_aleatorio()
	sprite.frame = datos["cuadro"]
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_tiempo = randf() * TAU
	# Aparece con un pequeño rebote
	scale = Vector2.ZERO
	var aparecer := create_tween()
	aparecer.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if _recogido:
		return
	_tiempo += delta
	sprite.position.y = -7.0 + roundf(sin(_tiempo * 3.0))  # flota 1 píxel arriba y abajo
	if _jugador_encima != null:
		_intentar_recoger(_jugador_encima)
	else:
		_atraer_con_iman(delta)


func _atraer_con_iman(delta: float) -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Jugador
	if jugador == null or not jugador.iman_activo or not jugador.tiene_espacio():
		return
	if global_position.distance_to(jugador.global_position) < jugador.radio_iman:
		# Acelera a medida que se acerca, para que se note el "jalón"
		global_position = global_position.move_toward(jugador.global_position, velocidad_atraccion * delta)
		sprite.rotation = sin(_tiempo * 20.0) * 0.25
	else:
		sprite.rotation = 0.0


func _intentar_recoger(jugador: Jugador) -> void:
	if not jugador.intentar_recoger(datos):
		return
	_recogido = true
	remove_from_group("residuos")
	set_deferred("monitoring", false)
	recogido.emit(datos)
	# Sube y se desvanece antes de desaparecer
	var salida := create_tween().set_parallel()
	salida.tween_property(sprite, "position:y", sprite.position.y - 10.0, 0.2)
	salida.tween_property(self, "modulate:a", 0.0, 0.2)
	salida.chain().tween_callback(queue_free)


func _on_body_entered(body: Node2D) -> void:
	if body is Jugador:
		_jugador_encima = body


func _on_body_exited(body: Node2D) -> void:
	if body == _jugador_encima:
		_jugador_encima = null
