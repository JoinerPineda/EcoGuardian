class_name Burbuja
extends Area2D
## Burbuja de jabón que dispara el jugador. Vuela en línea recta,
## golpea a las manchas de petróleo y revienta al chocar o al acabarse su tiempo.
## Pasa por encima del agua porque su máscara no incluye la capa "agua".

@export var velocidad := 150.0
@export var duracion := 0.7   ## segundos antes de reventar sola

var direccion := Vector2.RIGHT

var _reventada := false
var _tiempo := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var temporizador: Timer = $Temporizador


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	temporizador.timeout.connect(reventar)
	temporizador.start(duracion)


func _physics_process(delta: float) -> void:
	if _reventada:
		return
	_tiempo += delta
	position += direccion * velocidad * delta
	sprite.frame = int(_tiempo * 10.0) % 2  # alterna entre los dos cuadros


func _on_body_entered(body: Node2D) -> void:
	if _reventada:
		return
	if body.has_method("recibir_golpe"):
		body.recibir_golpe(direccion)
	reventar()


func reventar() -> void:
	if _reventada:
		return
	_reventada = true
	set_deferred("monitoring", false)
	var estallido := create_tween().set_parallel()
	estallido.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.12)
	estallido.tween_property(sprite, "modulate:a", 0.0, 0.12)
	estallido.chain().tween_callback(queue_free)
