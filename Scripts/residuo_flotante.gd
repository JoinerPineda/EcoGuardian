class_name ResiduoFlotante
extends PathFollow2D
## Residuo que flota por el río siguiendo el Path2D "RutaRio" de izquierda a derecha.
## Se recoge desde la orilla o el puente cuando pasa cerca del jugador.
## Si llega al final del río sin ser recogido, se escapa y sube la contaminación.
## Con el imán activo, el residuo sale del agua volando hacia el jugador.

signal recogido(datos: Dictionary)
signal escapo(datos: Dictionary)

@export var velocidad := 20.0        ## píxeles por segundo a lo largo del río
@export var amplitud_vaiven := 9.0   ## cuánto se mece hacia las orillas
@export var velocidad_atraccion := 160.0  ## con el imán activo

var datos: Dictionary = {}

var _tiempo := 0.0
var _terminado := false
var _jugador_cerca: Jugador = null
var _atraido := false
var _rio_vertical := false       ## en el nivel 2 el río baja de arriba hacia abajo
var _pos_sprite := Vector2.ZERO   ## posición original (local) del sprite y del área
var _pos_area := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area


func _ready() -> void:
	add_to_group("flotantes")
	loop = false
	rotates = false
	if datos.is_empty():
		datos = Reciclaje.residuo_aleatorio()
	sprite.frame = datos["cuadro"]
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_tiempo = randf() * TAU
	_pos_sprite = sprite.position
	var curva := (get_parent() as Path2D).curve
	if curva != null and curva.point_count > 1:
		var recorrido := curva.get_point_position(curva.point_count - 1) - curva.get_point_position(0)
		_rio_vertical = absf(recorrido.y) > absf(recorrido.x)
	_pos_area = area.position


func _process(delta: float) -> void:
	if _terminado:
		return
	_tiempo += delta
	if _actualizar_iman(delta):
		pass  # Mientras el imán lo jala, no avanza con la corriente
	else:
		progress += velocidad * delta
		# Vaivén: se acerca a una orilla y luego a la otra
		var vaiven := sin(_tiempo * 0.9) * amplitud_vaiven
		if _rio_vertical:
			h_offset = vaiven
		else:
			v_offset = vaiven
		sprite.rotation = sin(_tiempo * 2.2) * 0.3

	if _jugador_cerca != null and _jugador_cerca.intentar_recoger(datos):
		_retirar(true)
	elif progress_ratio >= 0.999:
		_retirar(false)


## Si el jugador tiene el imán y espacio en la mochila, el residuo vuela hacia él.
## Devuelve true mientras está siendo atraído.
func _actualizar_iman(delta: float) -> bool:
	var jugador := get_tree().get_first_node_in_group("jugador") as Jugador
	var puede := jugador != null and jugador.iman_activo and jugador.tiene_espacio() \
		and sprite.global_position.distance_to(jugador.global_position) < jugador.radio_iman
	if puede:
		_atraido = true
		var destino := jugador.global_position + Vector2(0, -4)
		sprite.global_position = sprite.global_position.move_toward(destino, velocidad_atraccion * delta)
		area.global_position = sprite.global_position
		sprite.rotation = sin(_tiempo * 20.0) * 0.25
		return true
	if _atraido:
		# Se acabó el imán (o se llenó la mochila): vuelve al agua
		sprite.position = sprite.position.move_toward(_pos_sprite, velocidad_atraccion * delta)
		area.position = area.position.move_toward(_pos_area, velocidad_atraccion * delta)
		if sprite.position == _pos_sprite:
			_atraido = false
		return true
	return false


func _retirar(fue_recogido: bool) -> void:
	_terminado = true
	remove_from_group("flotantes")
	area.set_deferred("monitoring", false)
	if fue_recogido:
		recogido.emit(datos)
		var salida := create_tween().set_parallel()
		salida.tween_property(sprite, "position:y", sprite.position.y - 12.0, 0.2)
		salida.tween_property(self, "modulate:a", 0.0, 0.2)
		salida.chain().tween_callback(queue_free)
	else:
		escapo.emit(datos)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Jugador:
		_jugador_cerca = body


func _on_body_exited(body: Node2D) -> void:
	if body == _jugador_cerca:
		_jugador_cerca = null
