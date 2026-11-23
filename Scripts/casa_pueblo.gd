@tool
class_name CasaPueblo
extends StaticBody2D
## Casa colonial de bahareque del nivel 2 (como las de Salamina o Aguadas).
## Hay 3 variantes de color en Assets/casas_pueblo.png.

@export_range(0, 2) var variante := 0:
	set(valor):
		variante = valor
		if is_node_ready():
			$Sprite.frame = variante


func _ready() -> void:
	$Sprite.frame = variante
