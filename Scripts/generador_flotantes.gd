class_name GeneradorFlotantes
extends Node
## Lanza basura al río cada cierto tiempo. Cada residuo flotante es un
## PathFollow2D que se agrega como hijo del Path2D "RutaRio" del mapa.

signal flotante_creado(flotante: ResiduoFlotante)

@export var escena_flotante: PackedScene
@export var mapa: Mapa
@export var primer_lanzamiento := 6.0
@export var intervalo_minimo := 9.0
@export var intervalo_maximo := 14.0
@export var velocidad_minima := 16.0
@export var velocidad_maxima := 24.0

var progreso := 0.0

@onready var temporizador: Timer = $Temporizador


func iniciar() -> void:
	temporizador.timeout.connect(_on_temporizador_timeout)
	temporizador.start(primer_lanzamiento)


func detener() -> void:
	temporizador.stop()


func _on_temporizador_timeout() -> void:
	var flotante := escena_flotante.instantiate() as ResiduoFlotante
	flotante.datos = Reciclaje.residuo_aleatorio()
	# Con el progreso, la basura baja un poco más rápido
	flotante.velocidad = randf_range(velocidad_minima, velocidad_maxima) * (1.0 + progreso * 0.3)
	mapa.ruta_rio.add_child(flotante)
	flotante_creado.emit(flotante)
	temporizador.start(randf_range(intervalo_minimo, intervalo_maximo) * (1.0 - progreso * 0.3))
