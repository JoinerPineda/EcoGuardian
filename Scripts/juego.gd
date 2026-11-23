extends Node2D
## Controla las reglas de la partida de "EcoGuardián":
## puntaje, combos, barra de contaminación, victoria y derrota.
## Se comunica con los demás nodos por medio de señales.
## Al empezar aplica los datos del nivel elegido (ver Scripts/niveles.gd):
## cambia el mapa, la meta, la contaminación, los generadores y los enemigos.

signal puntaje_cambiado(puntaje: int)
signal contaminacion_cambiada(porcentaje: float)
signal reciclados_cambiados(cantidad: int, meta: int)

# ---------------------------------------------------------------- reglas (editables en el Inspector)
@export_group("Meta")
@export var meta_reciclados := 25
@export_group("Puntos")
@export var puntos_acierto := 10
@export var puntos_error := -5
@export var puntos_combo := 15
@export var aciertos_para_combo := 3
@export_group("Contaminación (%)")
@export var contaminacion_inicial := 25.0
@export var aumento_por_residuo := 0.07  ## por segundo, por cada residuo sin recoger
@export var limpieza_natural := 0.3      ## por segundo, cuando no hay basura
@export var baja_por_acierto := 5.0
@export var sube_por_error := 5.0
@export var sube_por_escape := 4.0
@export var baja_por_mancha := 2.0
@export var sube_por_bolsa := 5.0   ## cada vez que una bolsa voladora toca al jugador
@export_group("Escenas")
@export var escena_texto: PackedScene

const COLOR_BUENO := Color(0.55, 1.0, 0.55)
const COLOR_MALO := Color(1.0, 0.45, 0.45)
const COLOR_COMBO := Color(1.0, 0.85, 0.3)
const COLOR_AMBIENTE_SUCIO := Color(0.78, 0.72, 0.66)
const ESCENA_TUTORIAL := preload("res://Escenas/Interfaz/Tutorial.tscn")

## Mensajes educativos que salen al derrotar enemigos (el primero siempre, luego a veces)
const DATOS_MANCHA := [
	"El aceite tapa la luz y el oxígeno que necesitan los peces",
	"Un litro de aceite puede contaminar miles de litros de agua",
]
const DATOS_BOLSA := [
	"Las bolsas duran cientos de años en el río. ¡Llévala a la caneca BLANCA!",
	"El viento lleva las bolsas al río. Usa bolsas de tela",
]

# ---------------------------------------------------------------- estado
var puntaje := 0
var contaminacion := 0.0
var reciclados := 0
var errores := 0
var racha := 0
var tiempo_jugado := 0.0
var terminado := false
var nivel := 1
var en_tutorial := false     ## mientras dura el tutorial la contaminación no sube
var _color_ambiente := Color.WHITE
var _datos_mostrados := {}   ## qué datos educativos ya se mostraron en esta partida

# ---------------------------------------------------------------- nodos
@onready var mapa: Mapa = $Mapa
@onready var jugador: Jugador = $Mapa/Jugador
@onready var hud: HUD = $HUD
@onready var menu_pausa: MenuPausa = $MenuPausa
@onready var pantalla_final: PantallaFinal = $PantallaFinal
@onready var generador_residuos: GeneradorResiduos = $GeneradorResiduos
@onready var generador_flotantes: GeneradorFlotantes = $GeneradorFlotantes
@onready var generador_enemigos: GeneradorEnemigos = $GeneradorEnemigos
@onready var ambiente: CanvasModulate = $Ambiente


func _ready() -> void:
	_aplicar_nivel()
	jugador.global_position = mapa.inicio.global_position
	_configurar_camara()
	_conectar_senales()

	# Estado inicial del HUD
	_cambiar_contaminacion(contaminacion_inicial)
	puntaje_cambiado.emit(puntaje)
	reciclados_cambiados.emit(reciclados, meta_reciclados)
	hud.actualizar_vida(jugador.vida, jugador.vida_maxima)
	hud.actualizar_mochila(jugador.mochila, jugador.seleccion)

	var datos := Niveles.datos(nivel)
	Sonido.reproducir_musica(datos["musica"])
	hud.mostrar_titulo_nivel(datos["titulo"], datos["nombre"])
	if _debe_mostrar_tutorial():
		# Se espera a que se quite el cartel del nivel para no taparlo
		en_tutorial = true
		get_tree().create_timer(2.3, false).timeout.connect(_empezar_tutorial)
	else:
		_empezar_partida()


## Arranca los generadores. Se llama al inicio o cuando termina el tutorial.
func _empezar_partida() -> void:
	en_tutorial = false
	generador_residuos.iniciar()
	generador_flotantes.iniciar()
	generador_enemigos.iniciar()
	hud.mostrar_mensaje(Niveles.datos(nivel)["mensaje_inicio"], COLOR_COMBO)


# ================================================================= NIVELES
func _aplicar_nivel() -> void:
	nivel = clampi(Guardado.nivel_actual, 1, Niveles.cantidad())
	var datos := Niveles.datos(nivel)
	if datos["mapa"] != mapa.scene_file_path:
		_cambiar_mapa(load(datos["mapa"]))
	meta_reciclados = datos["meta"]
	contaminacion_inicial = datos["contaminacion_inicial"]
	aumento_por_residuo = datos["aumento_por_residuo"]
	sube_por_escape = datos["sube_por_escape"]
	_color_ambiente = datos["color_ambiente"]
	for clave in datos["residuos"]:
		generador_residuos.set(clave, datos["residuos"][clave])
	for clave in datos["flotantes"]:
		generador_flotantes.set(clave, datos["flotantes"][clave])
	for clave in datos["enemigos"]:
		generador_enemigos.set(clave, datos["enemigos"][clave])
	generador_enemigos.tipos = datos["tipos_enemigo"]


## Reemplaza el mapa de Juego.tscn por el del nivel (el jugador se pasa al mapa nuevo).
func _cambiar_mapa(escena: PackedScene) -> void:
	var nuevo := escena.instantiate() as Mapa
	var viejo := mapa
	var indice := viejo.get_index()
	viejo.remove_child(jugador)
	remove_child(viejo)
	viejo.free()
	add_child(nuevo)
	move_child(nuevo, indice)
	nuevo.add_child(jugador)
	mapa = nuevo
	generador_residuos.mapa = nuevo
	generador_flotantes.mapa = nuevo
	generador_enemigos.mapa = nuevo


# ================================================================= TUTORIAL
## El tutorial sale en el nivel 1 la primera vez que se juega en el computador
## y también para cada estudiante nuevo que se registra en la trivia.
func _debe_mostrar_tutorial() -> bool:
	if not Niveles.datos(nivel)["tutorial"]:
		return false
	if not Guardado.tutorial_visto:
		return true
	return Evaluacion.hay_participante() and int(Evaluacion.participante_actual()["partidas"]) == 0


func _empezar_tutorial() -> void:
	en_tutorial = true
	var tutorial := ESCENA_TUTORIAL.instantiate() as Tutorial
	tutorial.juego = self
	tutorial.terminado.connect(_on_tutorial_terminado)
	add_child(tutorial)


func _on_tutorial_terminado() -> void:
	Guardado.marcar_tutorial_visto()
	_empezar_partida()


## Crea un residuo en el suelo cerca de un punto (lo usan el tutorial y la bolsa).
func soltar_residuo(datos: Dictionary, cerca_de: Vector2, distancia_min := 24.0, distancia_max := 70.0) -> Residuo:
	var posicion := mapa.posicion_libre_cercana(cerca_de, distancia_min, distancia_max)
	if posicion == Vector2.INF:
		posicion = mapa.posicion_libre_aleatoria(cerca_de, 0.0)
	if posicion == Vector2.INF:
		return null
	var residuo := generador_residuos.escena_residuo.instantiate() as Residuo
	residuo.datos = datos
	mapa.objetos.add_child(residuo)
	residuo.global_position = posicion
	return residuo


func _configurar_camara() -> void:
	var limites := mapa.rectangulo_en_pixeles()
	jugador.camara.limit_left = limites.position.x
	jugador.camara.limit_top = limites.position.y
	jugador.camara.limit_right = limites.end.x
	jugador.camara.limit_bottom = limites.end.y
	jugador.camara.reset_smoothing()


func _conectar_senales() -> void:
	# Jugador -> HUD y reglas
	jugador.mochila_cambiada.connect(hud.actualizar_mochila)
	jugador.vida_cambiada.connect(hud.actualizar_vida)
	jugador.iman_cambiado.connect(hud.actualizar_iman)
	jugador.caneca_cercana_cambiada.connect(hud.mostrar_ayuda_caneca)
	jugador.mensaje.connect(hud.mostrar_mensaje)
	jugador.murio.connect(_on_jugador_murio)
	# Juego -> HUD
	puntaje_cambiado.connect(hud.actualizar_puntaje)
	contaminacion_cambiada.connect(hud.actualizar_contaminacion)
	reciclados_cambiados.connect(hud.actualizar_reciclados)
	# Canecas (todas están en el grupo "canecas")
	for caneca in get_tree().get_nodes_in_group("canecas"):
		caneca.residuo_depositado.connect(_on_residuo_depositado)
	# Objetos que se crean durante la partida
	generador_flotantes.flotante_creado.connect(_on_flotante_creado)
	generador_enemigos.enemigo_creado.connect(_on_enemigo_creado)
	# Pausa
	menu_pausa.pausa_cambiada.connect(Sonido.atenuar_musica)


func _process(delta: float) -> void:
	if terminado:
		return
	tiempo_jugado += delta
	if en_tutorial:
		return
	# La contaminación sube sola mientras haya basura sin recoger
	var basura := get_tree().get_nodes_in_group("residuos").size() + get_tree().get_nodes_in_group("flotantes").size()
	if basura > 0:
		_cambiar_contaminacion(contaminacion + basura * aumento_por_residuo * delta)
	else:
		_cambiar_contaminacion(contaminacion - limpieza_natural * delta)
	if hud.iman_visible():
		hud.actualizar_tiempo_iman(jugador.tiempo_iman_restante())


# ================================================================= REGLAS
func _cambiar_contaminacion(valor: float) -> void:
	contaminacion = clampf(valor, 0.0, 100.0)
	contaminacion_cambiada.emit(contaminacion)
	var proporcion := contaminacion / 100.0
	mapa.actualizar_contaminacion(proporcion)
	# Todo el paisaje se ve más gris cuando el río está sucio
	ambiente.color = _color_ambiente.lerp(COLOR_AMBIENTE_SUCIO * _color_ambiente, proporcion)
	if contaminacion >= 100.0 and not terminado:
		_terminar(false, "La contaminación llegó al 100 %. El río colapsó.")


func _sumar_puntos(cantidad: int) -> void:
	puntaje = maxi(puntaje + cantidad, 0)
	puntaje_cambiado.emit(puntaje)


func _on_residuo_depositado(residuo: Dictionary, correcto: bool, caneca: Caneca) -> void:
	if terminado:
		return
	var posicion := caneca.global_position + Vector2(0, -26)
	if correcto:
		reciclados += 1
		racha += 1
		_sumar_puntos(puntos_acierto)
		_cambiar_contaminacion(contaminacion - baja_por_acierto)
		reciclados_cambiados.emit(reciclados, meta_reciclados)
		if racha % aciertos_para_combo == 0:
			# ¡Combo! Tres aciertos seguidos dan puntos extra
			_sumar_puntos(puntos_combo)
			_texto_flotante("+%d  ¡COMBO!" % (puntos_acierto + puntos_combo), posicion, COLOR_COMBO)
			hud.mostrar_combo(racha)
			Sonido.reproducir("combo")
		else:
			_texto_flotante("+%d" % puntos_acierto, posicion, COLOR_BUENO)
			Sonido.reproducir("acierto")
		_actualizar_progreso()
		if reciclados >= meta_reciclados and not en_tutorial:
			if Niveles.es_ultimo(nivel):
				_terminar(true, "¡Reciclaste %d residuos y salvaste el río del pueblo! Completaste los dos niveles." % reciclados)
			else:
				_terminar(true, "¡Reciclaste %d residuos y el río volvió a la vida!" % reciclados)
	else:
		errores += 1
		racha = 0
		_sumar_puntos(puntos_error)
		_cambiar_contaminacion(contaminacion + sube_por_error)
		_texto_flotante("%d" % puntos_error, posicion, COLOR_MALO)
		# Retroalimentación educativa: dice cuál era la caneca correcta
		hud.mostrar_mensaje("%s va en la caneca %s" % [residuo["nombre"], Reciclaje.nombre_caneca(residuo["caneca"])], COLOR_MALO)
		Sonido.reproducir("error")


func _actualizar_progreso() -> void:
	var progreso := clampf(float(reciclados) / meta_reciclados, 0.0, 1.0)
	generador_residuos.progreso = progreso
	generador_flotantes.progreso = progreso
	generador_enemigos.progreso = progreso


func _on_flotante_creado(flotante: ResiduoFlotante) -> void:
	flotante.escapo.connect(_on_flotante_escapo)


func _on_flotante_escapo(residuo: Dictionary) -> void:
	if terminado:
		return
	_cambiar_contaminacion(contaminacion + sube_por_escape)
	hud.mostrar_mensaje("¡Se escapó %s río abajo!" % residuo["nombre"].to_lower(), COLOR_MALO)
	Sonido.reproducir("escapa")


func _on_enemigo_creado(enemigo: Node2D) -> void:
	enemigo.derrotada.connect(_on_enemigo_derrotado)
	if enemigo.has_signal("robo"):
		enemigo.robo.connect(_on_robo)


func _on_enemigo_derrotado(enemigo: Node2D) -> void:
	if terminado:
		return
	_cambiar_contaminacion(contaminacion - baja_por_mancha)
	if enemigo is Bolsa:
		# La bolsa atrapada cae al suelo y hay que reciclarla
		_texto_flotante("¡Atrapada!", enemigo.global_position + Vector2(0, -20), COLOR_BUENO)
		# call_deferred: esto pasa dentro de una colisión y ahí no se pueden crear áreas
		soltar_residuo.call_deferred(Reciclaje.RESIDUO_BOLSA, enemigo.global_position, 0.0, 48.0)
		_dato_educativo("bolsa", DATOS_BOLSA)
	else:
		_texto_flotante("¡Limpio!", enemigo.global_position + Vector2(0, -16), COLOR_BUENO)
		_dato_educativo("mancha", DATOS_MANCHA)


## La primera vez siempre muestra el dato; después, una de cada tres veces.
func _dato_educativo(clave: String, datos: Array) -> void:
	var veces: int = _datos_mostrados.get(clave, 0)
	_datos_mostrados[clave] = veces + 1
	if veces == 0 or randf() < 0.33:
		hud.mostrar_mensaje(datos[veces % datos.size()], Color(0.6, 0.9, 1.0))


## Una bolsa voladora tocó al jugador: la contaminación sube y, si llevaba algo,
## le quita el residuo seleccionado (cae al suelo cerca). Si la mochila estaba
## vacía, la bolsa ya le quitó una vida (ver bolsa.gd).
func _on_robo(residuo: Dictionary, posicion: Vector2) -> void:
	if terminado:
		return
	_cambiar_contaminacion(contaminacion + sube_por_bolsa)
	_texto_flotante("+%d%% contaminación" % roundi(sube_por_bolsa), posicion + Vector2(0, -24), COLOR_MALO)
	if residuo.is_empty():
		hud.mostrar_mensaje("¡La bolsa te golpeó! -1 vida y +%d %% de contaminación" % roundi(sube_por_bolsa), COLOR_MALO)
	else:
		soltar_residuo.call_deferred(residuo, posicion, 30.0, 80.0)
		hud.mostrar_mensaje("¡La bolsa te quitó: %s! Cayó cerca" % str(residuo["nombre"]).to_lower(), COLOR_MALO)


func _on_jugador_murio() -> void:
	_terminar(false, "Los enemigos del río te dejaron sin energía.")


func _texto_flotante(texto: String, posicion: Vector2, color: Color) -> void:
	if escena_texto == null:
		return
	var etiqueta := escena_texto.instantiate() as TextoFlotante
	add_child(etiqueta)
	etiqueta.global_position = posicion
	etiqueta.mostrar(texto, color)


# ================================================================= FIN DE LA PARTIDA
func _terminar(gano: bool, motivo: String) -> void:
	if terminado:
		return
	terminado = true
	jugador.activo = false
	menu_pausa.habilitado = false
	generador_residuos.detener()
	generador_flotantes.detener()
	generador_enemigos.detener()

	var intentos := reciclados + errores
	var precision := float(reciclados) / intentos if intentos > 0 else 0.0
	var estrellas := Reciclaje.calcular_estrellas(gano, contaminacion, precision)
	var nuevo_record := Guardado.registrar_partida(puntaje, estrellas)
	if gano:
		Guardado.desbloquear_nivel(nivel + 1)
	# Datos de la partida para el análisis de la evaluación (trivia inicial/final)
	Evaluacion.registrar_partida(puntaje, precision, estrellas, gano, nivel)

	Sonido.detener_musica()
	Sonido.reproducir("victoria" if gano else "derrota", false)

	var resumen := {
		"gano": gano,
		"motivo": motivo,
		"nivel": nivel,
		"hay_siguiente": gano and not Niveles.es_ultimo(nivel),
		"puntaje": puntaje,
		"reciclados": reciclados,
		"meta": meta_reciclados,
		"precision": precision,
		"contaminacion": contaminacion,
		"tiempo": tiempo_jugado,
		"estrellas": estrellas,
		"mejor_puntaje": Guardado.mejor_puntaje,
		"nuevo_record": nuevo_record,
		"dato": Reciclaje.dato_aleatorio(),
	}
	# Pequeña pausa dramática antes de mostrar la pantalla final
	var espera := get_tree().create_timer(0.9)
	espera.timeout.connect(_mostrar_pantalla_final.bind(resumen))


func _mostrar_pantalla_final(resumen: Dictionary) -> void:
	get_tree().paused = true
	pantalla_final.mostrar(resumen)
