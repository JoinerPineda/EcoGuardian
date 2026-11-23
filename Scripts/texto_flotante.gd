class_name TextoFlotante
extends Node2D
## Texto corto (+10, -5, ¡COMBO!) que sube y se desvanece con un Tween.

@onready var etiqueta: Label = $Etiqueta


func mostrar(texto: String, color: Color) -> void:
	etiqueta.text = texto
	etiqueta.modulate = color
	var animacion := create_tween().set_parallel()
	animacion.tween_property(self, "position:y", position.y - 20.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animacion.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.45)
	animacion.chain().tween_callback(queue_free)
