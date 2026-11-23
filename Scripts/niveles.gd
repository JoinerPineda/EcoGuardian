class_name Niveles
extends RefCounted
## Datos de cada nivel. juego.gd los aplica al empezar la partida:
## mapa, meta, contaminación, ritmo de los generadores y tipos de enemigo.
## Para ajustar la dificultad basta con cambiar los números de esta lista.
##
## Uso: Niveles.datos(2)["meta"]

const LISTA := [
	{
		"titulo": "NIVEL 1",
		"nombre": "La finca cafetera",
		"mapa": "res://Escenas/Mapa.tscn",
		"meta": 12,                       # residuos bien reciclados para ganar
		"contaminacion_inicial": 20.0,
		"aumento_por_residuo": 0.05,      # % por segundo por cada residuo sin recoger
		"sube_por_escape": 4.0,
		"color_ambiente": Color(1.0, 1.0, 1.0),
		"musica": "res://Audio/musica.wav",               # bambuco
		"tutorial": true,
		"mensaje_inicio": "¡Limpia el río! Lleva cada residuo a su caneca",
		"residuos": {
			"cantidad_inicial": 4, "maximo_inicial": 5, "maximo_final": 8,
			"intervalo_inicial": 3.5, "intervalo_minimo": 2.2,
		},
		"flotantes": {
			"primer_lanzamiento": 8.0, "intervalo_minimo": 10.0, "intervalo_maximo": 15.0,
			"velocidad_minima": 14.0, "velocidad_maxima": 20.0,
		},
		"enemigos": { "primera_aparicion": 14.0, "intervalo": 14.0 },
		"tipos_enemigo": [
			{
				"escena": "res://Escenas/Personajes/Mancha.tscn", "grupo": "manchas",
				"maximo_inicial": 1, "maximo_final": 2, "ajustes": {},
			},
		],
	},
	{
		"titulo": "NIVEL 2",
		"nombre": "El pueblo",
		"mapa": "res://Escenas/Mapa2.tscn",
		"meta": 15,
		"contaminacion_inicial": 30.0,
		"aumento_por_residuo": 0.058,
		"sube_por_escape": 5.0,
		"color_ambiente": Color(1.0, 0.95, 0.86),   # luz cálida de la tarde
		"musica": "res://Audio/musica_nivel2.wav",        # cumbia
		"tutorial": false,
		"mensaje_inicio": "¡Cuidado con las bolsas voladoras! Te quitan residuos",
		"residuos": {
			"cantidad_inicial": 5, "maximo_inicial": 6, "maximo_final": 10,
			"intervalo_inicial": 3.0, "intervalo_minimo": 1.8,
		},
		"flotantes": {
			"primer_lanzamiento": 6.0, "intervalo_minimo": 8.0, "intervalo_maximo": 12.0,
			"velocidad_minima": 18.0, "velocidad_maxima": 26.0,
		},
		"enemigos": { "primera_aparicion": 8.0, "intervalo": 10.0 },
		"tipos_enemigo": [
			{
				"escena": "res://Escenas/Personajes/Mancha.tscn", "grupo": "manchas",
				"maximo_inicial": 1, "maximo_final": 3,
				"ajustes": { "velocidad_persecucion": 40.0 },
			},
			{
				"escena": "res://Escenas/Personajes/Bolsa.tscn", "grupo": "bolsas",
				"maximo_inicial": 1, "maximo_final": 2, "ajustes": {},
			},
		],
	},
]


static func cantidad() -> int:
	return LISTA.size()


static func datos(nivel: int) -> Dictionary:
	return LISTA[clampi(nivel, 1, LISTA.size()) - 1]


static func es_ultimo(nivel: int) -> bool:
	return nivel >= LISTA.size()
