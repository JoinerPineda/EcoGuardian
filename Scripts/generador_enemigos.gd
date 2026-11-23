class_name GeneradorEnemigos
extends Node
## Hace aparecer enemigos lejos del jugador.
## Cada nivel define sus "tipos" de enemigo (ver Scripts/niveles.gd): escena,
## grupo, cuántos puede haber al inicio y al final, y ajustes de sus @export.
## Si no se definen tipos, sólo aparecen manchas de petróleo.

signal enemigo_creado(enemigo: Node2D)

@export var escena_mancha: PackedScene
@export var mapa: Mapa
@export var primera_aparicion := 12.0
@export var intervalo := 13.0
@export var maximo_inicial := 1
@export var maximo_final := 4
@export var distancia_minima_al_jugador := 130.0

## Lista de Dictionary: { escena, grupo, maximo_inicial, maximo_final, ajustes }
var tipos: Array = []
var progreso := 0.0

var _escenas := {}   ## caché de escenas cargadas

@onready var temporizador: Timer = $Temporizador


func iniciar() -> void:
	if tipos.is_empty():
		tipos = [{ "escena": escena_mancha.resource_path, "grupo": "manchas",
			"maximo_inicial": maximo_inicial, "maximo_final": maximo_final, "ajustes": {} }]
	temporizador.timeout.connect(_on_temporizador_timeout)
	temporizador.start(primera_aparicion)


func detener() -> void:
	temporizador.stop()


func _on_temporizador_timeout() -> void:
	# Con el progreso aparecen un poco más seguido
	temporizador.start(intervalo * (1.0 - progreso * 0.25))
	var candidatos: Array = []
	for tipo in tipos:
		var maximo := roundi(lerpf(tipo["maximo_inicial"], tipo["maximo_final"], progreso))
		if get_tree().get_nodes_in_group(tipo["grupo"]).size() < maximo:
			candidatos.append(tipo)
	if candidatos.is_empty():
		return
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	var posicion := mapa.posicion_libre_aleatoria(jugador.global_position, distancia_minima_al_jugador)
	if posicion == Vector2.INF:
		return
	var elegido: Dictionary = candidatos.pick_random()
	var enemigo := _escena(elegido["escena"]).instantiate() as Node2D
	for clave in elegido["ajustes"]:
		enemigo.set(clave, elegido["ajustes"][clave])
	if "mapa" in enemigo:
		enemigo.mapa = mapa
	mapa.objetos.add_child(enemigo)
	enemigo.global_position = posicion
	enemigo_creado.emit(enemigo)


func _escena(ruta: String) -> PackedScene:
	if not _escenas.has(ruta):
		_escenas[ruta] = load(ruta)
	return _escenas[ruta]
