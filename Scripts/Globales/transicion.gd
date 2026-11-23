extends CanvasLayer
## Autoload "Transicion": funde a negro al cambiar de escena.
## Ejemplo: Transicion.cambiar_escena("res://Escenas/Juego.tscn")

const DURACION := 0.25

var _ocupada := false

@onready var cortina: ColorRect = $Cortina


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cortina.color.a = 0.0


func cambiar_escena(ruta: String) -> void:
	if _ocupada:
		return
	_ocupada = true
	var entrada := create_tween()
	entrada.tween_property(cortina, "color:a", 1.0, DURACION)
	await entrada.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(ruta)
	var salida := create_tween()
	salida.tween_property(cortina, "color:a", 0.0, DURACION)
	await salida.finished
	_ocupada = false


## Vuelve a cargar la escena actual (reiniciar la partida).
func reiniciar() -> void:
	cambiar_escena(get_tree().current_scene.scene_file_path)
