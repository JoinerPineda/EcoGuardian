class_name GeneradorResiduos
extends Node
## Hace aparecer residuos en el suelo cada cierto tiempo (Timer + PackedScene).
## Con el progreso de la partida aparecen más rápido y hay más a la vez.

signal residuo_creado(residuo: Residuo)

@export var escena_residuo: PackedScene
@export var mapa: Mapa
@export var cantidad_inicial := 5
@export var intervalo_inicial := 3.5
@export var intervalo_minimo := 1.8
@export var maximo_inicial := 6
@export var maximo_final := 11
@export var distancia_minima_al_jugador := 40.0

## Avance de la partida de 0.0 (inicio) a 1.0 (meta). Lo actualiza juego.gd
var progreso := 0.0

@onready var temporizador: Timer = $Temporizador


func iniciar() -> void:
	temporizador.timeout.connect(_on_temporizador_timeout)
	for i in cantidad_inicial:
		_crear_residuo()
	temporizador.start(intervalo_inicial)


func detener() -> void:
	temporizador.stop()


func _on_temporizador_timeout() -> void:
	var maximo := roundi(lerpf(maximo_inicial, maximo_final, progreso))
	if get_tree().get_nodes_in_group("residuos").size() < maximo:
		_crear_residuo()
	temporizador.start(lerpf(intervalo_inicial, intervalo_minimo, progreso))


func _crear_residuo() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	var cerca_de := jugador.global_position if jugador != null else Vector2.INF
	var posicion := mapa.posicion_libre_aleatoria(cerca_de, distancia_minima_al_jugador)
	if posicion == Vector2.INF:
		return
	var residuo := escena_residuo.instantiate() as Residuo
	residuo.datos = Reciclaje.residuo_aleatorio()
	mapa.objetos.add_child(residuo)
	residuo.global_position = posicion
	residuo_creado.emit(residuo)
