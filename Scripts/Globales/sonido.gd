extends Node
## Autoload "Sonido": reproduce efectos y música desde cualquier script.
## Ejemplo: Sonido.reproducir("acierto")
## La tecla M (o el botón del altavoz) silencia todo el juego; se recuerda en Guardado.

signal silencio_cambiado(silenciado: bool)

const EFECTOS := {
	"recoger": preload("res://Audio/recoger.wav"),
	"acierto": preload("res://Audio/acierto.wav"),
	"error": preload("res://Audio/error.wav"),
	"combo": preload("res://Audio/combo.wav"),
	"burbuja": preload("res://Audio/burbuja.wav"),
	"golpe": preload("res://Audio/golpe.wav"),
	"dano": preload("res://Audio/dano.wav"),
	"iman": preload("res://Audio/iman.wav"),
	"mancha_derrotada": preload("res://Audio/mancha_derrotada.wav"),
	"escapa": preload("res://Audio/escapa.wav"),
	"lleno": preload("res://Audio/lleno.wav"),
	"boton": preload("res://Audio/boton.wav"),
	"victoria": preload("res://Audio/victoria.wav"),
	"derrota": preload("res://Audio/derrota.wav"),
}
const MUSICA := preload("res://Audio/musica.wav")   ## bambuco: menú, trivia y nivel 1
var _pistas := {}   ## caché de otras pistas (p. ej. la cumbia del nivel 2)
const CANTIDAD_CANALES := 8
const VOLUMEN_MUSICA := -9.0

var _canales: Array[AudioStreamPlayer] = []
var _musica: AudioStreamPlayer


func _ready() -> void:
	# El sonido debe seguir funcionando aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in CANTIDAD_CANALES:
		var canal := AudioStreamPlayer.new()
		canal.volume_db = -4.0
		add_child(canal)
		_canales.append(canal)
	_musica = AudioStreamPlayer.new()
	_musica.stream = MUSICA
	_musica.volume_db = VOLUMEN_MUSICA
	add_child(_musica)
	# Al terminar la pista vuelve a empezar (bucle)
	_musica.finished.connect(_musica.play)
	# La ventana no se cierra sola: primero se detiene el audio (ver _notification)
	get_tree().auto_accept_quit = false
	_aplicar_silencio()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("silenciar"):
		alternar_silencio()
		get_viewport().set_input_as_handled()


func esta_silenciado() -> bool:
	return Guardado.silencio


## Apaga o prende todo el sonido (bus Master) y lo recuerda para la próxima vez.
func alternar_silencio() -> void:
	Guardado.silencio = not Guardado.silencio
	Guardado.guardar()
	_aplicar_silencio()
	if not Guardado.silencio:
		reproducir("boton", false)
	silencio_cambiado.emit(Guardado.silencio)


func _aplicar_silencio() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), Guardado.silencio)


## Reproduce un efecto. Varía un poco el tono para que no suene repetitivo.
func reproducir(nombre: String, variar_tono := true) -> void:
	if not EFECTOS.has(nombre):
		push_warning("Sonido desconocido: %s" % nombre)
		return
	var canal := _canal_libre()
	canal.stream = EFECTOS[nombre]
	canal.pitch_scale = randf_range(0.95, 1.05) if variar_tono else 1.0
	canal.play()


## Sin argumentos suena el bambuco principal. Con una ruta suena esa pista
## (si ya estaba sonando, no se reinicia).
func reproducir_musica(ruta := "") -> void:
	var pista: AudioStream = MUSICA
	if ruta != "":
		if not _pistas.has(ruta):
			_pistas[ruta] = load(ruta)
		pista = _pistas[ruta]
	_musica.volume_db = VOLUMEN_MUSICA
	if _musica.stream != pista:
		_musica.stream = pista
		_musica.play()
	elif not _musica.playing:
		_musica.play()


func detener_musica() -> void:
	_musica.stop()


## Baja la música mientras el juego está en pausa.
func atenuar_musica(atenuar: bool) -> void:
	_musica.volume_db = VOLUMEN_MUSICA - (12.0 if atenuar else 0.0)


## Cierra el juego deteniendo antes el audio (así Godot no avisa de recursos en uso).
func salir_del_juego() -> void:
	_musica.stop()
	for canal in _canales:
		canal.stop()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit()


## Al cerrar la ventana con la X también se sale de forma ordenada.
func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		salir_del_juego()


func _canal_libre() -> AudioStreamPlayer:
	for canal in _canales:
		if not canal.playing:
			return canal
	return _canales[0]
