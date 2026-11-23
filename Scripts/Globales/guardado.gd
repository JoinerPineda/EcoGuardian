extends Node
## Autoload "Guardado": guarda el récord y las preferencias en disco (carpeta user://).
## En Windows el archivo queda en %APPDATA%/Godot/app_userdata/EcoGuardián/

const RUTA := "user://ecoguardian.cfg"

var mejor_puntaje := 0
var mejores_estrellas := 0
var partidas_jugadas := 0
var nivel_desbloqueado := 1   ## el nivel 2 se desbloquea al ganar el nivel 1
var tutorial_visto := false
var silencio := false         ## sonido apagado con el botón del altavoz o la tecla M

## Nivel que se va a jugar (no se guarda en disco: lo eligen el menú o la pantalla final)
var nivel_actual := 1


func _ready() -> void:
	cargar()


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		return  # Primera vez: todavía no hay récord
	mejor_puntaje = archivo.get_value("record", "mejor_puntaje", 0)
	mejores_estrellas = archivo.get_value("record", "mejores_estrellas", 0)
	partidas_jugadas = archivo.get_value("record", "partidas_jugadas", 0)
	nivel_desbloqueado = archivo.get_value("progreso", "nivel_desbloqueado", 1)
	tutorial_visto = archivo.get_value("progreso", "tutorial_visto", false)
	silencio = archivo.get_value("opciones", "silencio", false)


func guardar() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("record", "mejor_puntaje", mejor_puntaje)
	archivo.set_value("record", "mejores_estrellas", mejores_estrellas)
	archivo.set_value("record", "partidas_jugadas", partidas_jugadas)
	archivo.set_value("progreso", "nivel_desbloqueado", nivel_desbloqueado)
	archivo.set_value("progreso", "tutorial_visto", tutorial_visto)
	archivo.set_value("opciones", "silencio", silencio)
	var error := archivo.save(RUTA)
	if error != OK:
		push_warning("No se pudo guardar el récord (error %d)" % error)


## Registra el resultado de una partida. Devuelve true si es un nuevo récord.
func registrar_partida(puntaje: int, estrellas: int) -> bool:
	partidas_jugadas += 1
	var nuevo_record := puntaje > mejor_puntaje
	if nuevo_record:
		mejor_puntaje = puntaje
	mejores_estrellas = maxi(mejores_estrellas, estrellas)
	guardar()
	return nuevo_record


func desbloquear_nivel(nivel: int) -> void:
	if nivel > nivel_desbloqueado:
		nivel_desbloqueado = mini(nivel, Niveles.cantidad())
		guardar()


func marcar_tutorial_visto() -> void:
	if not tutorial_visto:
		tutorial_visto = true
		guardar()
