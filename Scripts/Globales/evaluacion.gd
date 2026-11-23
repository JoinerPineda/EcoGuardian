extends Node
## Autoload "Evaluacion": trivia inicial y final para medir el aprendizaje.
##
## Flujo de un participante:
##   1. En el menú pulsa "Jugar" -> si no hay participante en curso, hace la
##      TRIVIA INICIAL (pre-test) antes de su primera partida.
##   2. Juega una o varias partidas (juego.gd llama a registrar_partida()).
##   3. Hace la TRIVIA FINAL (post-test) con OTRAS 5 preguntas de los mismos temas, responde
##      una encuesta corta de experiencia y ve la comparación antes/después.
##
## Los datos se guardan en user://evaluaciones.json (para el juego) y se
## exportan siempre a user://evaluaciones.csv (para abrir en Excel o
## Google Sheets y analizar los resultados de todo el grupo).

enum Modo { INICIAL, FINAL }

const RUTA_DATOS := "user://evaluaciones.json"
## Si cambia el banco de preguntas, sube este número: los datos viejos se
## guardan aparte (evaluaciones_v<N>_respaldo.json) y se empieza de cero.
const VERSION_DATOS := 3
const RUTA_CSV := "user://evaluaciones.csv"
const SEPARADOR_CSV := ";"   ## Excel en español usa ";" como separador de listas
const UMBRAL_REFORZAR := 0.6  ## Preguntas con menos de 60 % de aciertos en la final

## Nombres de las opciones cuando la respuesta es una caneca (mismo orden que Reciclaje.Caneca)
const NOMBRES_CANECAS := ["Blanca", "Verde", "Negra"]

## Dos bancos de 5 preguntas: uno para la trivia INICIAL y otro, con preguntas
## distintas, para la FINAL. La pregunta N de cada banco mide el mismo TEMA
## (ver TEMAS), así se puede comparar tema por tema qué se aprendió jugando.
## - "cuadro": ícono de Assets/residuos.png (-1 = sin ícono)
## - "opciones": vacío = las tres canecas; si no, lista de 3 textos
## - "correcta": índice de la opción correcta (para canecas, valor de Reciclaje.Caneca)
const TEMAS := ["Caneca blanca", "Caneca verde", "Caneca negra", "Petróleo en el río", "Bolsas plásticas"]

const PREGUNTAS_INICIAL := [
	{
		"corto": "Botella plástica",
		"texto": "Te tomaste una gaseosa. ¿En qué caneca va la botella plástica limpia y seca?",
		"cuadro": 0, "opciones": [], "correcta": Reciclaje.Caneca.BLANCA,
		"explicacion": "El plástico limpio y seco es aprovechable: va en la caneca BLANCA.",
	},
	{
		"corto": "Cáscara de banano",
		"texto": "¿Dónde va la cáscara de banano?",
		"cuadro": 5, "opciones": [], "correcta": Reciclaje.Caneca.VERDE,
		"explicacion": "Las cáscaras son orgánicas y sirven para hacer compost: caneca VERDE.",
	},
	{
		"corto": "Empaque metalizado",
		"texto": "¿Dónde va el empaque metalizado de un paquete de papas?",
		"cuadro": 11, "opciones": [], "correcta": Reciclaje.Caneca.NEGRA,
		"explicacion": "Los empaques metalizados no son aprovechables: caneca NEGRA.",
	},
	{
		"corto": "Daño del petróleo",
		"texto": "¿Por qué una mancha de petróleo o aceite le hace daño al río?",
		"cuadro": -1,
		"opciones": [
			"Impide que entren la luz y el oxígeno que necesitan los peces",
			"Hace que el agua corra más rápido",
			"No hace daño: el agua la limpia sola",
		],
		"correcta": 0,
		"explicacion": "La capa de aceite tapa el agua: no entran la luz ni el oxígeno.",
	},
	{
		"corto": "Peligro de las bolsas",
		"texto": "¿Por qué las bolsas plásticas son un peligro para los ríos?",
		"cuadro": -1,
		"opciones": [
			"El viento las lleva al agua y tardan cientos de años en degradarse",
			"Se disuelven en el agua en pocos días",
			"Los peces se las comen y les sirven de alimento",
		],
		"correcta": 0,
		"explicacion": "El viento las arrastra al río y duran cientos de años.",
	},
]

const PREGUNTAS_FINAL := [
	{
		"corto": "Lata",
		"texto": "¿En qué caneca va una lata de gaseosa vacía y limpia?",
		"cuadro": 1, "opciones": [], "correcta": Reciclaje.Caneca.BLANCA,
		"explicacion": "Los metales limpios y secos son aprovechables: caneca BLANCA.",
	},
	{
		"corto": "Pulpa de café",
		"texto": "En una finca de Caldas sobra pulpa de café. ¿En qué caneca va?",
		"cuadro": 7, "opciones": [], "correcta": Reciclaje.Caneca.VERDE,
		"explicacion": "La pulpa de café es orgánica y se convierte en abono: caneca VERDE.",
	},
	{
		"corto": "Icopor sucio",
		"texto": "¿Dónde va un plato de icopor con restos de comida?",
		"cuadro": 12, "opciones": [], "correcta": Reciclaje.Caneca.NEGRA,
		"explicacion": "El icopor sucio no se puede aprovechar: caneca NEGRA.",
	},
	{
		"corto": "Peces y aceite",
		"texto": "Si un río tiene una capa de aceite encima, ¿qué les pasa a los peces?",
		"cuadro": -1,
		"opciones": [
			"Les falta el oxígeno que necesitan para vivir",
			"Nadan más rápido y más contentos",
			"Nada: el aceite los protege del sol",
		],
		"correcta": 0,
		"explicacion": "El aceite no deja pasar el oxígeno ni la luz: los peces se ahogan.",
	},
	{
		"corto": "Bolsa plástica",
		"texto": "Atrapaste una bolsa plástica limpia y seca. ¿En qué caneca va?",
		"cuadro": 14, "opciones": [], "correcta": Reciclaje.Caneca.BLANCA,
		"explicacion": "Las bolsas plásticas limpias y secas se reciclan: caneca BLANCA.",
	},
]

## Encuesta de experiencia (escala 1 a 5) que se responde al final.
const ENCUESTA := [
	{ "corto": "Diversión", "texto": "¿Qué tan divertido fue el juego?" },
	{ "corto": "Facilidad", "texto": "¿Qué tan fácil fue entender cómo se juega?" },
	{ "corto": "Aprendizaje", "texto": "¿Cuánto aprendiste sobre separar los residuos?" },
	{ "corto": "Recomendaría", "texto": "¿Recomendarías el juego a un amigo?" },
]

## Pon en false (por código o en el Inspector remoto) para jugar sin trivia.
var activa := true
## Qué trivia va a mostrar la escena Trivia.tscn
var modo := Modo.INICIAL

## Lista de participantes. Cada uno es un Dictionary (ver _nuevo_registro).
var registros: Array = []
## Índice en "registros" del participante en curso (-1 = ninguno)
var actual := -1


func _ready() -> void:
	cargar()


# ================================================================= ESTADO
func hay_participante() -> bool:
	return actual >= 0 and actual < registros.size()


func participante_actual() -> Dictionary:
	return registros[actual] if hay_participante() else {}


func nombre_actual() -> String:
	return str(participante_actual().get("nombre", ""))


## true si al pulsar "Jugar" primero hay que hacer la trivia inicial.
func necesita_trivia_inicial() -> bool:
	return activa and not hay_participante()


## true si el participante ya jugó al menos una partida y le falta la trivia final.
func trivia_final_pendiente() -> bool:
	if not activa or not hay_participante():
		return false
	var registro := participante_actual()
	return (registro["final"] as Array).is_empty() and int(registro["partidas"]) > 0


# ================================================================= REGISTRO DE RESULTADOS
## Se llama al terminar la trivia inicial: crea al participante.
func guardar_inicial(nombre: String, respuestas: Array, segundos: float) -> void:
	var registro := _nuevo_registro(nombre)
	registro["inicial"] = respuestas.duplicate()
	registro["segundos_inicial"] = roundi(segundos)
	registros.append(registro)
	actual = registros.size() - 1
	guardar()


## La llama juego.gd al terminar cada partida.
func registrar_partida(puntaje: int, precision: float, estrellas: int, gano: bool, nivel := 1) -> void:
	if not hay_participante():
		return  # Se ejecutó Juego.tscn directamente (F6) o la trivia está desactivada
	var registro := participante_actual()
	registro["partidas"] = int(registro["partidas"]) + 1
	if gano:
		registro["victorias"] = int(registro["victorias"]) + 1
		registro["nivel_maximo"] = maxi(int(registro.get("nivel_maximo", 0)), nivel)
	registro["mejor_puntaje"] = maxi(int(registro["mejor_puntaje"]), puntaje)
	registro["mejor_precision"] = maxf(float(registro["mejor_precision"]), precision)
	registro["mejores_estrellas"] = maxi(int(registro["mejores_estrellas"]), estrellas)
	guardar()


## Se llama al terminar la trivia final. Devuelve el índice del registro
## (para guardar después la encuesta) y cierra al participante.
func guardar_final(respuestas: Array, segundos: float) -> int:
	if not hay_participante():
		return -1
	var indice := actual
	var registro := participante_actual()
	registro["final"] = respuestas.duplicate()
	registro["segundos_final"] = roundi(segundos)
	actual = -1  # El siguiente "Jugar" empieza con un participante nuevo
	guardar()
	return indice


func guardar_encuesta(indice: int, valores: Array) -> void:
	if indice < 0 or indice >= registros.size():
		return
	registros[indice]["encuesta"] = valores.duplicate()
	guardar()


## Deja al participante actual sin trivia final y permite registrar a otro.
func cambiar_participante() -> void:
	actual = -1
	guardar()


func borrar_todo() -> void:
	registros.clear()
	actual = -1
	guardar()


func _nuevo_registro(nombre: String) -> Dictionary:
	return {
		"id": _siguiente_id(),
		"fecha": Time.get_datetime_string_from_system(false, true),
		"nombre": nombre,
		"inicial": [],
		"final": [],
		"encuesta": [],
		"partidas": 0,
		"victorias": 0,
		"mejor_puntaje": 0,
		"mejor_precision": 0.0,
		"mejores_estrellas": 0,
		"nivel_maximo": 0,
		"segundos_inicial": 0,
		"segundos_final": 0,
	}


func _siguiente_id() -> int:
	var mayor := 0
	for registro in registros:
		mayor = maxi(mayor, int(registro["id"]))
	return mayor + 1


# ================================================================= CALIFICACIÓN
func total_preguntas() -> int:
	return TEMAS.size()


## Banco de preguntas de la trivia inicial (final = false) o de la final (final = true).
static func preguntas(final: bool) -> Array:
	return PREGUNTAS_FINAL if final else PREGUNTAS_INICIAL


static func es_correcta(indice_pregunta: int, respuesta, final := false) -> bool:
	return int(respuesta) == int(preguntas(final)[indice_pregunta]["correcta"])


static func aciertos(respuestas: Array, final := false) -> int:
	var cuenta := 0
	for i in mini(respuestas.size(), TEMAS.size()):
		if es_correcta(i, respuestas[i], final):
			cuenta += 1
	return cuenta


## Nombre visible de una opción (sirve para canecas y para preguntas de texto).
static func texto_opcion(indice_pregunta: int, opcion: int, final := false) -> String:
	var opciones: Array = preguntas(final)[indice_pregunta]["opciones"]
	if opciones.is_empty():
		return "Caneca " + str(NOMBRES_CANECAS[opcion]).to_lower()
	return str(opciones[opcion])


# ================================================================= ANÁLISIS DEL GRUPO
## Resume los resultados de todos los participantes para la pantalla del docente.
## La comparación antes/después usa sólo a quienes hicieron LAS DOS trivias.
func resumen() -> Dictionary:
	var completos: Array = []
	var solo_inicial := 0
	for registro in registros:
		if (registro["inicial"] as Array).is_empty():
			continue
		if (registro["final"] as Array).is_empty():
			solo_inicial += 1
		else:
			completos.append(registro)

	var n := completos.size()
	var total := total_preguntas()
	var suma_inicial := 0.0
	var suma_final := 0.0
	var mejoraron := 0
	var por_pregunta: Array = []
	for i in total:
		por_pregunta.append({ "corto": TEMAS[i], "inicial": 0.0, "final": 0.0 })
	var suma_encuesta: Array = []
	var cuenta_encuesta: Array = []
	for i in ENCUESTA.size():
		suma_encuesta.append(0.0)
		cuenta_encuesta.append(0)

	for registro in completos:
		var a_ini := aciertos(registro["inicial"], false)
		var a_fin := aciertos(registro["final"], true)
		suma_inicial += float(a_ini) / total
		suma_final += float(a_fin) / total
		if a_fin > a_ini:
			mejoraron += 1
		for i in total:
			if es_correcta(i, registro["inicial"][i]):
				por_pregunta[i]["inicial"] += 1.0 / n
			if es_correcta(i, registro["final"][i], true):
				por_pregunta[i]["final"] += 1.0 / n
		var encuesta: Array = registro["encuesta"]
		for i in mini(encuesta.size(), ENCUESTA.size()):
			if int(encuesta[i]) > 0:
				suma_encuesta[i] += float(encuesta[i])
				cuenta_encuesta[i] += 1

	var promedios_encuesta: Array = []
	for i in ENCUESTA.size():
		promedios_encuesta.append(suma_encuesta[i] / cuenta_encuesta[i] if cuenta_encuesta[i] > 0 else 0.0)

	# Temas a reforzar: menos aciertos en la trivia final, de peor a mejor
	var a_reforzar: Array = []
	if n > 0:
		for pregunta in por_pregunta:
			if pregunta["final"] < UMBRAL_REFORZAR:
				a_reforzar.append(pregunta)
		a_reforzar.sort_custom(func(a, b): return a["final"] < b["final"])

	return {
		"completos": n,
		"solo_inicial": solo_inicial,
		"promedio_inicial": suma_inicial / n if n > 0 else 0.0,
		"promedio_final": suma_final / n if n > 0 else 0.0,
		"porcentaje_mejoraron": float(mejoraron) / n if n > 0 else 0.0,
		"por_pregunta": por_pregunta,
		"encuesta": promedios_encuesta,
		"a_reforzar": a_reforzar,
	}


# ================================================================= GUARDAR / CARGAR
func cargar() -> void:
	if not FileAccess.file_exists(RUTA_DATOS):
		return
	var texto := FileAccess.get_file_as_string(RUTA_DATOS)
	var datos = JSON.parse_string(texto)
	if typeof(datos) != TYPE_DICTIONARY:
		push_warning("No se pudo leer %s" % RUTA_DATOS)
		return
	var version := int(datos.get("version", 1))
	if version != VERSION_DATOS:
		# Datos de otro banco de preguntas: no son comparables, se guardan aparte
		var respaldo := "user://evaluaciones_v%d_respaldo.json" % version
		DirAccess.rename_absolute(ProjectSettings.globalize_path(RUTA_DATOS), ProjectSettings.globalize_path(respaldo))
		if FileAccess.file_exists(RUTA_CSV):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(RUTA_CSV),
				ProjectSettings.globalize_path(respaldo.replace(".json", ".csv")))
		return
	registros = datos.get("registros", [])
	actual = int(datos.get("actual", -1))
	if not hay_participante():
		actual = -1


func guardar() -> void:
	var archivo := FileAccess.open(RUTA_DATOS, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar la evaluación (error %d)" % FileAccess.get_open_error())
		return
	archivo.store_string(JSON.stringify({ "version": VERSION_DATOS, "registros": registros, "actual": actual }, "\t"))
	archivo.close()
	exportar_csv()


## Escribe una fila por participante. Se abre directo en Excel / Google Sheets.
func exportar_csv() -> void:
	var archivo := FileAccess.open(RUTA_CSV, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo exportar el CSV (error %d)" % FileAccess.get_open_error())
		return
	archivo.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))  # BOM: Excel muestra bien las tildes
	var encabezado := PackedStringArray([
		"id", "fecha", "participante", "estado",
		"aciertos_inicial", "aciertos_final", "total_preguntas", "mejora",
		"porcentaje_inicial", "porcentaje_final",
		"partidas", "victorias", "nivel_maximo_superado", "mejor_puntaje", "mejor_precision_%", "mejores_estrellas",
		"segundos_trivia_inicial", "segundos_trivia_final",
	])
	for item in ENCUESTA:
		encabezado.append("encuesta_" + str(item["corto"]).to_lower())
	for i in TEMAS.size():
		encabezado.append("P%d_inicial (%s: %s)" % [i + 1, TEMAS[i], PREGUNTAS_INICIAL[i]["corto"]])
	for i in TEMAS.size():
		encabezado.append("P%d_final (%s: %s)" % [i + 1, TEMAS[i], PREGUNTAS_FINAL[i]["corto"]])
	archivo.store_csv_line(encabezado, SEPARADOR_CSV)

	var total := total_preguntas()
	for registro in registros:
		var inicial: Array = registro["inicial"]
		var final: Array = registro["final"]
		var encuesta: Array = registro["encuesta"]
		var completo := not final.is_empty()
		var a_ini := aciertos(inicial, false)
		var a_fin := aciertos(final, true)
		var fila := PackedStringArray([
			str(int(registro["id"])), str(registro["fecha"]), str(registro["nombre"]),
			"completo" if completo else "solo inicial",
			str(a_ini), str(a_fin) if completo else "", str(total),
			str(a_fin - a_ini) if completo else "",
			str(roundi(100.0 * a_ini / total)),
			str(roundi(100.0 * a_fin / total)) if completo else "",
			str(int(registro["partidas"])), str(int(registro["victorias"])), str(int(registro.get("nivel_maximo", 0))),
			str(int(registro["mejor_puntaje"])), str(roundi(float(registro["mejor_precision"]) * 100.0)),
			str(int(registro["mejores_estrellas"])),
			str(int(registro["segundos_inicial"])), str(int(registro["segundos_final"])) if completo else "",
		])
		for i in ENCUESTA.size():
			fila.append(str(int(encuesta[i])) if i < encuesta.size() else "")
		for i in total:
			fila.append(("1" if es_correcta(i, inicial[i]) else "0") if i < inicial.size() else "")
		for i in total:
			fila.append(("1" if es_correcta(i, final[i], true) else "0") if i < final.size() else "")
		archivo.store_csv_line(fila, SEPARADOR_CSV)
	archivo.close()


## Ruta real de la carpeta de datos (para mostrarla o abrirla).
func carpeta_datos() -> String:
	return ProjectSettings.globalize_path("user://")
