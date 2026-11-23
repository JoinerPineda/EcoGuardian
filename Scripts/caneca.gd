@tool
class_name Caneca
extends StaticBody2D
## Caneca de reciclaje. Su color se elige con la propiedad "tipo" en el Inspector
## (gracias a @tool el cambio se ve también en el editor).
## Cuando el jugador entra en su ZonaDeposito puede depositar con la tecla E.

## Se emite cada vez que recibe un residuo. "correcto" indica si era su caneca.
signal residuo_depositado(residuo: Dictionary, correcto: bool, caneca: Caneca)

@export var tipo: Reciclaje.Caneca = Reciclaje.Caneca.BLANCA:
	set(valor):
		tipo = valor
		if is_node_ready():
			_actualizar_aspecto()

@onready var sprite: Sprite2D = $Sprite
@onready var indicador: Label = $Indicador
@onready var zona_deposito: Area2D = $ZonaDeposito


func _ready() -> void:
	_actualizar_aspecto()
	indicador.visible = false
	if Engine.is_editor_hint():
		return  # En el editor no se conectan señales de juego
	add_to_group("canecas")
	zona_deposito.body_entered.connect(_on_zona_body_entered)
	zona_deposito.body_exited.connect(_on_zona_body_exited)
	# El indicador "E" sube y baja suavemente (Tween en bucle)
	var flotar := create_tween().set_loops()
	flotar.tween_property(indicador, "position:y", indicador.position.y - 2.0, 0.4).set_trans(Tween.TRANS_SINE)
	flotar.tween_property(indicador, "position:y", indicador.position.y, 0.4).set_trans(Tween.TRANS_SINE)


func _actualizar_aspecto() -> void:
	sprite.frame = int(tipo)


## Recibe un residuo de la mochila del jugador y avisa si era correcto.
func recibir_residuo(residuo: Dictionary) -> void:
	var correcto: bool = int(residuo["caneca"]) == int(tipo)
	_animar(correcto)
	residuo_depositado.emit(residuo, correcto, self)


func _animar(correcto: bool) -> void:
	# Rebote elástico de la caneca
	sprite.scale = Vector2(1.3, 0.75)
	var rebote := create_tween()
	rebote.tween_property(sprite, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Destello verde (acierto) o rojo (error)
	sprite.modulate = Color(0.6, 1.6, 0.6) if correcto else Color(1.8, 0.5, 0.5)
	var destello := create_tween()
	destello.tween_property(sprite, "modulate", Color.WHITE, 0.35)


# Se usa el grupo "jugador" en vez de "body is Jugador" para que la caneca
# no dependa del script del jugador (así también funciona en el editor con @tool).
func _on_zona_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		indicador.visible = true
		body.establecer_caneca_cercana(self)


func _on_zona_body_exited(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		indicador.visible = false
		body.salir_de_caneca(self)
