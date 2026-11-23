class_name Mapa
extends Node2D
## Nivel del río. Contiene las capas de baldosas (TileMapLayer), la ruta del río,
## la casa, las canecas y el contenedor "Objetos" donde aparecen residuos y enemigos.
## El nodo raíz tiene y_sort_enabled: lo que está más abajo en pantalla se dibuja delante.
##
## Capas (de atrás hacia adelante):
##   Suelo (z -4) -> Agua (z -3, con shader) -> RutaRio (z -2, basura flotante)
##   -> Puente (z -1) -> Obstaculos / Casa / Canecas / Objetos / Jugador (z 0, ordenados por Y)

const TAM_CELDA := 16
const MASCARA_OCUPADO := 1 | 8 | 32  ## capas mundo + recogibles + agua

@onready var suelo: TileMapLayer = $Suelo
@onready var agua: TileMapLayer = $Agua
@onready var obstaculos: TileMapLayer = $Obstaculos
@onready var ruta_rio: Path2D = $RutaRio
@onready var objetos: Node2D = $Objetos
@onready var inicio: Marker2D = $Inicio

var _celdas_generables: Array[Vector2i] = []


func _ready() -> void:
	_calcular_celdas_generables()


## Busca las celdas donde puede aparecer basura o enemigos usando el dato
## personalizado "generable" del TileSet.
func _calcular_celdas_generables() -> void:
	_celdas_generables.clear()
	for celda in suelo.get_used_cells():
		var datos := suelo.get_cell_tile_data(celda)
		if datos == null or not datos.get_custom_data("generable"):
			continue
		if agua.get_cell_source_id(celda) != -1 or obstaculos.get_cell_source_id(celda) != -1:
			continue
		# No usar celdas tapadas por la copa de un árbol alto (que está en la celda de abajo)
		var debajo := celda + Vector2i.DOWN
		if obstaculos.get_cell_source_id(debajo) != -1 and obstaculos.get_cell_atlas_coords(debajo).y == 2 \
				and obstaculos.get_cell_atlas_coords(debajo).x <= 1:
			continue
		_celdas_generables.append(celda)


## Rectángulo del mapa en píxeles (para los límites de la cámara).
func rectangulo_en_pixeles() -> Rect2i:
	var celdas := suelo.get_used_rect()
	return Rect2i(celdas.position * TAM_CELDA, celdas.size * TAM_CELDA)


## Devuelve una posición libre al azar, lejos de un punto.
## Si no encuentra ninguna devuelve Vector2.INF.
func posicion_libre_aleatoria(lejos_de: Vector2, distancia_minima: float) -> Vector2:
	if _celdas_generables.is_empty():
		return Vector2.INF
	var espacio := get_world_2d().direct_space_state
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.collision_mask = MASCARA_OCUPADO
	consulta.collide_with_areas = true
	for intento in 30:
		var celda: Vector2i = _celdas_generables.pick_random()
		var posicion := to_global(suelo.map_to_local(celda)) + Vector2(randf_range(-3, 3), randf_range(0, 5))
		if posicion.distance_to(lejos_de) < distancia_minima:
			continue
		consulta.position = posicion
		if espacio.intersect_point(consulta, 1).is_empty():
			return posicion
	return Vector2.INF


## Devuelve una posición libre a una distancia entre "minima" y "maxima" de un punto
## (para soltar residuos cerca del jugador). Vector2.INF si no encuentra.
func posicion_libre_cercana(punto: Vector2, minima: float, maxima: float) -> Vector2:
	var espacio := get_world_2d().direct_space_state
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.collision_mask = MASCARA_OCUPADO
	consulta.collide_with_areas = true
	var cercanas: Array[Vector2] = []
	for celda in _celdas_generables:
		var posicion := to_global(suelo.map_to_local(celda))
		var distancia := posicion.distance_to(punto)
		if distancia >= minima and distancia <= maxima:
			cercanas.append(posicion)
	cercanas.shuffle()
	for posicion in cercanas.slice(0, 25):
		consulta.position = posicion + Vector2(randf_range(-3, 3), randf_range(0, 4))
		if espacio.intersect_point(consulta, 1).is_empty():
			return consulta.position
	return Vector2.INF


## Cambia el color del agua (shader) según la contaminación (0.0 a 1.0).
func actualizar_contaminacion(valor: float) -> void:
	var material_agua := agua.material as ShaderMaterial
	if material_agua != null:
		material_agua.set_shader_parameter("contaminacion", clampf(valor, 0.0, 1.0))
