class_name MenuPausa
extends CanvasLayer
## Menú de pausa (Esc o P). Su process_mode es "Always" para seguir
## funcionando mientras el árbol de escenas está en pausa.

signal pausa_cambiada(pausado: bool)

const RUTA_MENU := "res://Escenas/MenuPrincipal.tscn"

var habilitado := true   ## juego.gd lo desactiva cuando termina la partida

@onready var boton_continuar: Button = $Panel/Contenido/Continuar
@onready var boton_reiniciar: Button = $Panel/Contenido/Reiniciar
@onready var boton_menu: Button = $Panel/Contenido/Menu


func _ready() -> void:
	visible = false
	boton_continuar.pressed.connect(alternar_pausa)
	boton_reiniciar.pressed.connect(_reiniciar)
	boton_menu.pressed.connect(_ir_al_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not habilitado:
		return
	if event.is_action_pressed("pausa"):
		alternar_pausa()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("reiniciar"):
		_reiniciar()
		get_viewport().set_input_as_handled()


func alternar_pausa() -> void:
	var pausar := not get_tree().paused
	get_tree().paused = pausar
	visible = pausar
	pausa_cambiada.emit(pausar)
	Sonido.reproducir("boton", false)
	if pausar:
		boton_continuar.grab_focus()


func _reiniciar() -> void:
	habilitado = false
	Sonido.atenuar_musica(false)
	Transicion.reiniciar()


func _ir_al_menu() -> void:
	habilitado = false
	Sonido.atenuar_musica(false)
	Transicion.cambiar_escena(RUTA_MENU)
