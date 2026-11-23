class_name BotonSonido
extends Button
## Botón pequeño con un altavoz: silencia o activa todo el sonido del juego.
## También se puede usar la tecla M en cualquier momento.
## Se usa en el menú principal y en el menú de pausa.

const TEXTURA := preload("res://Assets/sonido.png")

var _icono_activo := AtlasTexture.new()
var _icono_mudo := AtlasTexture.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_NONE   # no le roba el foco a los demás botones
	_icono_activo.atlas = TEXTURA
	_icono_activo.region = Rect2(0, 0, 12, 12)
	_icono_mudo.atlas = TEXTURA
	_icono_mudo.region = Rect2(12, 0, 12, 12)
	pressed.connect(Sonido.alternar_silencio)
	Sonido.silencio_cambiado.connect(_actualizar)
	_actualizar(Sonido.esta_silenciado())


func _actualizar(silenciado: bool) -> void:
	icon = _icono_mudo if silenciado else _icono_activo
	tooltip_text = "Activar sonido (M)" if silenciado else "Silenciar (M)"
	modulate = Color(1, 0.7, 0.7) if silenciado else Color.WHITE
