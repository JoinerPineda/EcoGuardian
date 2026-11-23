extends SceneTree
## HERRAMIENTA DE DESARROLLO (no se ejecuta durante el juego).
## Genera a partir de los textos MAPA (nivel 1) y MAPA_2 (nivel 2):
##   - Assets/tileset.tres          TileSet con colisiones, dato "generable" y orden Y
##   - Assets/jugador_frames.tres   SpriteFrames del jugador (4 direcciones)
##   - Assets/mancha_frames.tres    SpriteFrames de la mancha de petróleo
##   - Shaders/agua_material.tres   Material del agua (nivel 1: río azul que corre a la derecha)
##   - Shaders/agua_material_2.tres Material del agua (nivel 2: río verdoso que corre hacia abajo)
##   - Escenas/Mapa.tscn            Nivel 1 "La finca cafetera" (río horizontal)
##   - Escenas/Mapa2.tscn           Nivel 2 "El pueblo" (río vertical que cruza el pueblo)
##
## Uso (desde una terminal, en la carpeta del proyecto):
##   godot --headless --script res://Scripts/Herramientas/constructor_mapa.gd
## ¡Ojo! Sobrescribe Mapa.tscn y Mapa2.tscn. Si prefieres, edita Mapa.tscn directamente en el
## editor de Godot con el pintor de baldosas (pestaña TileMap).
##
## Leyenda del mapa (cada carácter es una celda de 16x16 px):
##   #  borde (arbustos y árboles)   .  pasto      =  camino     P  plaza
##   ~  río                          o  estanque   B  puente     T  árbol
##   G  guadua                       c  cafeto     r  roca       f  cerca
##   h  terreno de la casa           H  casa (esquina inferior central)
##   b  caneca blanca   v  caneca verde   n  caneca negra   S  inicio del jugador
## Letras extra del nivel 2 (el pueblo):
##   a  calle de adoquín    d  andén (baldosas)   Q  puente sobre río vertical
##   C  casa colonial (esquina inferior central)  x  terreno de la casa
##   L  farol   Y  guayacán amarillo   k  banca   m  matera con flores   F  fuente
## Las celdas de pasto o andén que tocan el agua se pintan solas como orilla
## (arena en el nivel 1, malecón de ladrillo en el nivel 2).

const MAPA := [
	"################################################",
	"##............................................##",
	"#.....T...ccc.cc.......T.....T......T..........#",
	"#..T..............fffff..........T..........T..#",
	"#.......r.c.cccc...hhh....GG............G......#",
	"~~~~~~~~...........hhh.........................#",
	"~~~~~~~~~.cccc.c...hHh.......~~~~~~~~~...G.....#",
	"~~~~~~~~~~.......=====......~~~~~~~~~~~........#",
	"#......~~~~c.ccc.==......T.~~~~~~~~~~~~~.....T.#",
	"#..GG...~~~~.....==...r...~~~~.G.G...~~~~.T....#",
	"#........~~~~....==......~~~~.........~~~~.....#",
	"#.........~~~~~~~BB~~~~~~~~~...........~~~~~~~~~",
	"#.T........~~~~~~BB~~~~~~~~......r......~~~~~~~~",
	"#........T..~~~~~BB~~~~~~~...............~~~~~~~",
	"#......r.....G...==.....G.............=....G.G.#",
	"#...oooo.........==..........T........=........#",
	"#..oooooo........==...............T...=........#",
	"#.oooooooo.T.....==.....T.............=r.......#",
	"#.oooooooo....rPPPPPPPr...............=......T.#",
	"#..oooooo.....PPbPvPnPP...r....T......=........#",
	"#...oooo......PPPPPPPPP...............=........#",
	"#...==========PPPPPPPPP=====================...#",
	"#.............PPPPSPPPP........................#",
	"#.........T...PPPPPPPPP.....T..............T...#",
	"#...T........r....................T............#",
	"#........................T...........T......r..#",
	"#......T....T..T.....T..................T......#",
	"##...T.........................T..............##",
	"###..........................................###",
	"################################################"
]

const MAPA_2 := [
	"#########################~~~~###############",
	"#........................~~~~..............#",
	"#.xxx.xxx...xxx.xxx......~~~~...xxx.xxx....#",
	"#.xxx.xxx...xxx.xxx......~~~~...xxx.xxx....#",
	"#.xCx.xCx...xCx.xCx......~~~~...xCx.xCx....#",
	"#dLdddddddLddddLddddddddd~~~~ddLddddLddddLd#",
	"#aaaaaaaaaaaaaaaaaaaaaaaaQQQQaaaaaaaaaaaaaa#",
	"#aaaaaaaaaaaaaaaaaaaaaaaaQQQQaaaaaaaaaaaaaa#",
	"#dddddddddddddddddddddddd~~~~dddddddddddddd#",
	"#..YddddddddddddY.......~~~~...............#",
	"#..dddddddddddddd.m.....~~~~....Y.....k.T..#",
	"#..ddkdddFdddkddd...r..~~~~................#",
	"#..dddddddddddddd.....~~~~..........Y.....r#",
	"#..dmddddddddddmd..m..~~~~.....r...........#",
	"#..ddddbdvdnddddd....~~~~..........k.......#",
	"#..dddddddddddddd..r.~~~~........Y.......T.#",
	"#..ddddddSddddddd....~~~~..................#",
	"#..YddddddddddddY....~~~~.............T....#",
	"#dLdddddddLddddLddddd~~~~ddddddLddddLddddLd#",
	"#aaaaaaaaaaaaaaaaaaaaQQQQaaaaaaaaaaaaaaaaaa#",
	"#aaaaaaaaaaaaaaaaaaaaQQQQaaaaaaaaaaaaaaaaaa#",
	"#dddddddddddddddddddd~~~~dddddddddddddddddd#",
	"#....................~~~~..................#",
	"#..xxx.xxx..xxx..T...~~~~......xxx.xxx.xxx.#",
	"#..xxx.xxx..xxx.......~~~~..T..xxx.xxx.xxx.#",
	"#..xCx.xCx..xCx.......~~~~....YxCx.xCx.xCx.#",
	"#...............Y.T...~~~~.................#",
	"#.T........T..........~~~~...T.....T.....T.#",
	"#......................~~~~................#",
	"#######################~~~~#################",
]

## Configuración de cada mapa que se construye
const MAPAS := [
	{
		"texto": "MAPA", "salida": "res://Escenas/Mapa.tscn", "material": "res://Shaders/agua_material.tres",
		"rio_vertical": false, "orilla": Vector2i(5, 0), "plaza": Vector2i(4, 0),
		"agua": { "color_limpio": Color(0.22, 0.58, 0.86), "direccion_corriente": Vector2(1, 0) },
	},
	{
		"texto": "MAPA_2", "salida": "res://Escenas/Mapa2.tscn", "material": "res://Shaders/agua_material_2.tres",
		"rio_vertical": true, "orilla": Vector2i(5, 1), "plaza": Vector2i(4, 1),
		"agua": {
			"color_limpio": Color(0.2, 0.62, 0.72), "color_medio": Color(0.36, 0.5, 0.36),
			"direccion_corriente": Vector2(0, 1),
		},
	},
]

# Coordenadas de cada baldosa dentro de Assets/tileset.png
const PASTO := Vector2i(0, 0)
const PASTO_FLORES := Vector2i(1, 0)
const PASTO_ALTO := Vector2i(2, 0)
const CAMINO := Vector2i(3, 0)
const PLAZA := Vector2i(4, 0)
const ARENA := Vector2i(5, 0)
const BOSQUE := Vector2i(6, 0)
const AGUA := Vector2i(0, 1)
const AGUA_SOMBRA := Vector2i(1, 1)
const PUENTE_IZQ := Vector2i(2, 1)
const PUENTE_DER := Vector2i(3, 1)
const ARBOL := Vector2i(0, 2)
const GUADUA := Vector2i(1, 2)
const ARBUSTO := Vector2i(2, 2)
const CAFETO := Vector2i(3, 2)
const ROCA := Vector2i(4, 2)
const CERCA := Vector2i(5, 2)
# Baldosas del nivel 2
const ADOQUIN := Vector2i(7, 0)
const ANDEN := Vector2i(4, 1)
const MALECON := Vector2i(5, 1)
const PUENTE_ARRIBA := Vector2i(6, 1)   # puente sobre río vertical (baranda arriba)
const PUENTE_ABAJO := Vector2i(7, 1)    # (baranda abajo)
const GUAYACAN := Vector2i(6, 2)        # 1x2
const FAROL := Vector2i(7, 2)           # 1x2
const BANCA := Vector2i(2, 3)
const MATERA := Vector2i(3, 3)
const FUENTE_AGUA := Vector2i(4, 3)

const FUENTE := 0             # id de la fuente del atlas
const CAPA_MUNDO := 0         # capa física 0 -> capa de colisión 1 "mundo"
const CAPA_AGUA := 1          # capa física 1 -> capa de colisión 6 "agua"
const ALT_NO_GENERABLE := 1   # baldosa alternativa de pasto donde no aparece basura
const TAM := 16


func _init() -> void:
	_guardar(_crear_tileset(), "res://Assets/tileset.tres")
	_guardar(_crear_frames_jugador(), "res://Assets/jugador_frames.tres")
	_guardar(_crear_frames_mancha(), "res://Assets/mancha_frames.tres")
	for config in MAPAS:
		var material_agua := ShaderMaterial.new()
		material_agua.shader = load("res://Shaders/agua.gdshader")
		# Se fijan todos los parámetros (si no, Godot guarda "null" en los que no se tocan)
		material_agua.set_shader_parameter("contaminacion", 0.25)
		material_agua.set_shader_parameter("color_limpio", Color(0.22, 0.58, 0.86))
		material_agua.set_shader_parameter("color_medio", Color(0.30, 0.52, 0.42))
		material_agua.set_shader_parameter("color_sucio", Color(0.40, 0.33, 0.22))
		material_agua.set_shader_parameter("velocidad_corriente", 6.0)
		for parametro in config["agua"]:
			material_agua.set_shader_parameter(parametro, config["agua"][parametro])
		_guardar(material_agua, config["material"])

		# Se vuelven a cargar desde disco para que el mapa los use como recursos externos
		var texto: Array = MAPA if config["texto"] == "MAPA" else MAPA_2
		var mapa := _crear_mapa(texto, config, load("res://Assets/tileset.tres"), load(config["material"]))
		var escena := PackedScene.new()
		var error := escena.pack(mapa)
		if error != OK:
			push_error("No se pudo empaquetar el mapa: %d" % error)
		_guardar(escena, config["salida"])
		mapa.free()
	print("Constructor: listo.")
	quit()


func _guardar(recurso: Resource, ruta: String) -> void:
	var error := ResourceSaver.save(recurso, ruta)
	print("  guardado %s (%s)" % [ruta, "OK" if error == OK else "ERROR %d" % error])


# ================================================================= TILESET
func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


func _colision(datos: TileData, capa: int, puntos: PackedVector2Array) -> void:
	datos.set_collision_polygons_count(capa, 1)
	datos.set_collision_polygon_points(capa, 0, puntos)


func _crear_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TAM, TAM)
	# Capas de física: obstáculos (capa 1) y agua (capa 6)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(CAPA_MUNDO, 1)
	tileset.set_physics_layer_collision_mask(CAPA_MUNDO, 0)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(CAPA_AGUA, 32)
	tileset.set_physics_layer_collision_mask(CAPA_AGUA, 0)
	# Dato personalizado: ¿puede aparecer basura en esta baldosa?
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "generable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)

	var fuente := TileSetAtlasSource.new()
	fuente.texture = load("res://Assets/tileset.png")
	fuente.texture_region_size = Vector2i(TAM, TAM)
	tileset.add_source(fuente, FUENTE)

	# Suelos
	for coords in [PASTO, PASTO_FLORES, PASTO_ALTO, CAMINO, PLAZA, ARENA, ADOQUIN, ANDEN, MALECON]:
		fuente.create_tile(coords)
		fuente.get_tile_data(coords, 0).set_custom_data("generable", true)
	fuente.create_tile(BOSQUE)
	var alternativa := fuente.create_alternative_tile(PASTO, ALT_NO_GENERABLE)
	fuente.get_tile_data(PASTO, alternativa).set_custom_data("generable", false)
	alternativa = fuente.create_alternative_tile(ANDEN, ALT_NO_GENERABLE)
	fuente.get_tile_data(ANDEN, alternativa).set_custom_data("generable", false)

	# Agua (bloquea al jugador y a los enemigos, no a las burbujas)
	fuente.create_tile(AGUA)
	_colision(fuente.get_tile_data(AGUA, 0), CAPA_AGUA, _rect(-8, -8, 8, 8))
	fuente.create_tile(AGUA_SOMBRA)
	fuente.create_tile(PUENTE_IZQ)
	fuente.create_tile(PUENTE_DER)
	fuente.create_tile(PUENTE_ARRIBA)
	fuente.create_tile(PUENTE_ABAJO)

	# Obstáculos altos (1x2 celdas): el dibujo sube 8 px y se ordena por la base del tronco
	for coords in [ARBOL, GUADUA, GUAYACAN, FAROL]:
		fuente.create_tile(coords, Vector2i(1, 2))
		var datos := fuente.get_tile_data(coords, 0)
		datos.texture_origin = Vector2i(0, 8)
		datos.y_sort_origin = 5
	_colision(fuente.get_tile_data(ARBOL, 0), CAPA_MUNDO, _rect(-3, -1, 3, 6))
	_colision(fuente.get_tile_data(GUADUA, 0), CAPA_MUNDO, _rect(-6, -1, 6, 7))
	_colision(fuente.get_tile_data(GUAYACAN, 0), CAPA_MUNDO, _rect(-3, -1, 3, 6))
	_colision(fuente.get_tile_data(FAROL, 0), CAPA_MUNDO, _rect(-3, 1, 3, 5))

	# Obstáculos de una celda
	var obstaculos := {
		ARBUSTO: [_rect(-8, -8, 8, 8), 4],
		CAFETO: [_rect(-5, -3, 5, 5), 4],
		ROCA: [_rect(-6, -3, 6, 4), 3],
		CERCA: [_rect(-8, -2, 8, 4), 3],
		BANCA: [_rect(-8, -5, 8, 2), 2],
		MATERA: [_rect(-6, -2, 6, 6), 5],
		FUENTE_AGUA: [_rect(-7, -4, 7, 4), 4],
	}
	for coords in obstaculos:
		fuente.create_tile(coords)
		var datos := fuente.get_tile_data(coords, 0)
		_colision(datos, CAPA_MUNDO, obstaculos[coords][0])
		datos.y_sort_origin = obstaculos[coords][1]
	return tileset


# ================================================================= SPRITEFRAMES
func _agregar_animacion(frames: SpriteFrames, nombre: String, textura: Texture2D, celdas: Array, fps: float, tam := 16) -> void:
	frames.add_animation(nombre)
	frames.set_animation_speed(nombre, fps)
	frames.set_animation_loop(nombre, true)
	for celda in celdas:
		var atlas := AtlasTexture.new()
		atlas.atlas = textura
		atlas.region = Rect2(celda.x * tam, celda.y * tam, tam, tam)
		frames.add_frame(nombre, atlas)


func _crear_frames_jugador() -> SpriteFrames:
	var textura: Texture2D = load("res://Assets/jugador.png")
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var direcciones := ["abajo", "arriba", "izquierda", "derecha"]  # filas de jugador.png
	for fila in direcciones.size():
		var nombre: String = direcciones[fila]
		_agregar_animacion(frames, "quieto_" + nombre, textura, [Vector2i(0, fila)], 1.0)
		_agregar_animacion(frames, "caminar_" + nombre, textura,
			[Vector2i(0, fila), Vector2i(1, fila), Vector2i(2, fila), Vector2i(3, fila)], 8.0)
	return frames


func _crear_frames_mancha() -> SpriteFrames:
	var textura: Texture2D = load("res://Assets/mancha.png")
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_agregar_animacion(frames, "mover", textura, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], 6.0)
	_agregar_animacion(frames, "golpe", textura, [Vector2i(4, 0)], 1.0)
	return frames


# ================================================================= MAPA
var _texto: Array = []          # mapa que se está construyendo
var _orilla := ARENA


func _letra(x: int, y: int) -> String:
	if y < 0 or y >= _texto.size() or x < 0 or x >= _texto[0].length():
		return "#"
	return _texto[y][x]


func _junto_al_agua(x: int, y: int) -> bool:
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _letra(x + d.x, y + d.y) in ["~", "o", "B", "Q"]:
			return true
	return false


func _pasto_variado(x: int, y: int) -> Vector2i:
	if _junto_al_agua(x, y):
		return _orilla
	var azar := absi(x * 73856093 ^ y * 19349663) % 100
	if azar < 12:
		return PASTO_FLORES
	if azar < 24:
		return PASTO_ALTO
	return PASTO


func _capa(nombre: String, tileset: TileSet, z: int, orden_y: bool) -> TileMapLayer:
	var capa := TileMapLayer.new()
	capa.name = nombre
	capa.tile_set = tileset
	capa.z_index = z
	capa.y_sort_enabled = orden_y
	return capa


func _agregar(padre: Node, hijo: Node, duenio: Node) -> void:
	padre.add_child(hijo)
	hijo.owner = duenio


func _crear_mapa(texto: Array, config: Dictionary, tileset: TileSet, material_agua: Material) -> Node2D:
	_texto = texto
	_orilla = config["orilla"]
	var plaza: Vector2i = config["plaza"]
	var raiz := Node2D.new()
	raiz.name = "Mapa"
	raiz.y_sort_enabled = true
	raiz.set_script(load("res://Scripts/mapa.gd"))

	var suelo := _capa("Suelo", tileset, -4, false)
	var agua := _capa("Agua", tileset, -3, false)
	agua.material = material_agua
	var ruta := Path2D.new()
	ruta.name = "RutaRio"
	ruta.z_index = -2
	var puente := _capa("Puente", tileset, -1, false)
	var obstaculos := _capa("Obstaculos", tileset, 0, true)
	for nodo in [suelo, agua, ruta, puente, obstaculos]:
		_agregar(raiz, nodo, raiz)

	var escena_casa: PackedScene = load("res://Escenas/Objetos/Casa.tscn")
	var escena_caneca: PackedScene = load("res://Escenas/Objetos/Caneca.tscn")
	var escena_casa_pueblo: PackedScene = load("res://Escenas/Objetos/CasaPueblo.tscn")
	var numero_casa := 0
	var canecas := Node2D.new()
	canecas.name = "Canecas"
	canecas.y_sort_enabled = true
	var objetos := Node2D.new()
	objetos.name = "Objetos"
	objetos.y_sort_enabled = true
	var inicio := Marker2D.new()
	inicio.name = "Inicio"

	for y in texto.size():
		for x in texto[y].length():
			var c := Vector2i(x, y)
			var letra: String = texto[y][x]
			match letra:
				"#":
					suelo.set_cell(c, FUENTE, BOSQUE)
					var es_arbol: bool = (x * 7 + y * 3) % 4 == 0 and _letra(x, y - 1) == "#"
					obstaculos.set_cell(c, FUENTE, ARBOL if es_arbol else ARBUSTO)
				"~", "o":
					agua.set_cell(c, FUENTE, AGUA)
				"B":
					agua.set_cell(c, FUENTE, AGUA_SOMBRA)
					puente.set_cell(c, FUENTE, PUENTE_IZQ if _letra(x - 1, y) != "B" else PUENTE_DER)
				"=":
					suelo.set_cell(c, FUENTE, CAMINO)
				"P", "b", "v", "n", "S":
					suelo.set_cell(c, FUENTE, plaza)
				"h", "H":
					suelo.set_cell(c, FUENTE, PASTO, ALT_NO_GENERABLE)
				"x", "C":
					suelo.set_cell(c, FUENTE, ANDEN, ALT_NO_GENERABLE)
				"Q":
					agua.set_cell(c, FUENTE, AGUA_SOMBRA)
					puente.set_cell(c, FUENTE, PUENTE_ARRIBA if _letra(x, y - 1) != "Q" else PUENTE_ABAJO)
				"a":
					suelo.set_cell(c, FUENTE, ADOQUIN)
				"d":
					suelo.set_cell(c, FUENTE, _orilla if _junto_al_agua(x, y) else ANDEN)
				"T", "G", "c", "r", "f", "Y":
					suelo.set_cell(c, FUENTE, _pasto_variado(x, y))
					var obstaculo: Vector2i = {"T": ARBOL, "G": GUADUA, "c": CAFETO, "r": ROCA, "f": CERCA, "Y": GUAYACAN}[letra]
					obstaculos.set_cell(c, FUENTE, obstaculo)
				"L", "k", "m", "F":
					suelo.set_cell(c, FUENTE, ANDEN)
					var objeto: Vector2i = {"L": FAROL, "k": BANCA, "m": MATERA, "F": FUENTE_AGUA}[letra]
					obstaculos.set_cell(c, FUENTE, objeto)
				_:
					suelo.set_cell(c, FUENTE, _pasto_variado(x, y))

			var centro := Vector2(x * TAM + TAM / 2.0, y * TAM + TAM / 2.0)
			match letra:
				"H":
					var casa := escena_casa.instantiate()
					casa.name = "Casa"
					casa.position = Vector2(centro.x, (y + 1) * TAM)
					_agregar(raiz, casa, raiz)
				"C":
					var casa_pueblo := escena_casa_pueblo.instantiate()
					casa_pueblo.name = "Casa%d" % numero_casa
					casa_pueblo.variante = numero_casa % 3
					numero_casa += 1
					casa_pueblo.position = Vector2(centro.x, (y + 1) * TAM)
					_agregar(raiz, casa_pueblo, raiz)
				"b", "v", "n":
					var caneca := escena_caneca.instantiate()
					caneca.name = {"b": "CanecaBlanca", "v": "CanecaVerde", "n": "CanecaNegra"}[letra]
					caneca.tipo = {"b": 0, "v": 1, "n": 2}[letra]
					caneca.position = centro + Vector2(0, 6)
					canecas.add_child(caneca)
				"S":
					inicio.position = centro

	_agregar(raiz, canecas, raiz)
	for caneca in canecas.get_children():
		caneca.owner = raiz
	_agregar(raiz, objetos, raiz)
	_agregar(raiz, inicio, raiz)

	# Ruta del río: centro del agua en cada columna (río horizontal, de izquierda
	# a derecha) o en cada fila (río vertical, de arriba hacia abajo)
	var curva := Curve2D.new()
	if config["rio_vertical"]:
		for y in range(-1, texto.size() + 1):
			var fila := clampi(y, 0, texto.size() - 1)
			var columnas: Array[int] = []
			for x in texto[fila].length():
				if texto[fila][x] in ["~", "Q"]:
					columnas.append(x)
			if columnas.is_empty():
				continue
			var centro_x: float = (columnas.min() + columnas.max()) / 2.0
			curva.add_point(Vector2(centro_x * TAM + TAM / 2.0, y * TAM + TAM / 2.0))
	else:
		for x in range(-1, texto[0].length() + 1):
			var columna := clampi(x, 0, texto[0].length() - 1)
			var filas: Array[int] = []
			for y in texto.size():
				if texto[y][columna] in ["~", "B"]:
					filas.append(y)
			if filas.is_empty():
				continue
			var centro_y: float = (filas.min() + filas.max()) / 2.0
			curva.add_point(Vector2(x * TAM + TAM / 2.0, centro_y * TAM + TAM / 2.0))
	ruta.curve = curva
	return raiz
