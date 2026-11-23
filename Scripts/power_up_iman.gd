class_name PowerUpIman
extends Area2D
## Power-up que sueltan a veces las manchas derrotadas.
## Al tocarlo, el jugador atrae los residuos cercanos durante unos segundos.

@export var duracion_efecto := 10.0   ## segundos que dura el imán
@export var tiempo_en_suelo := 10.0  ## si nadie lo recoge, desaparece

var _tiempo := 0.0
var _recogido := false

@onready var sprite: Sprite2D = $Sprite
@onready var temporizador: Timer = $Temporizador


func _ready() -> void:
	add_to_group("power_ups")
	body_entered.connect(_on_body_entered)
	temporizador.timeout.connect(_desaparecer)
	temporizador.start(tiempo_en_suelo)
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_tiempo += delta
	sprite.position.y = -9.0 + roundf(sin(_tiempo * 4.0) * 1.5)
	sprite.frame = int(_tiempo * 4.0) % 2
	# Parpadea cuando le quedan menos de 3 segundos
	if temporizador.time_left < 3.0:
		sprite.visible = int(_tiempo * 10.0) % 2 == 0


func _on_body_entered(body: Node2D) -> void:
	if _recogido or not body is Jugador:
		return
	_recogido = true
	body.activar_iman(duracion_efecto)
	set_deferred("monitoring", false)
	var salida := create_tween().set_parallel()
	salida.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	salida.tween_property(self, "modulate:a", 0.0, 0.2)
	salida.chain().tween_callback(queue_free)


func _desaparecer() -> void:
	if not _recogido:
		queue_free()
