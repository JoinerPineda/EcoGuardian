class_name Reciclaje
extends RefCounted
## Catálogo de residuos y reglas de clasificación.
##
## Usa el código de colores de Colombia (Resolución 2184 de 2019 del
## Ministerio de Ambiente, vigente desde el 1 de enero de 2021):
##   - BLANCA: aprovechables limpios y secos (plástico, vidrio, metales, papel y cartón).
##   - VERDE:  orgánicos aprovechables (restos de comida cruda, cáscaras, poda).
##   - NEGRA:  no aprovechables (servilletas y papel higiénico usados,
##             papeles metalizados, icopor sucio, tapabocas...).
## Al ser una clase con class_name, se puede usar desde cualquier script
## sin instanciarla: Reciclaje.residuo_aleatorio(), Reciclaje.Caneca.VERDE, etc.

enum Caneca { BLANCA, VERDE, NEGRA }

const NOMBRES_CANECA := {
	Caneca.BLANCA: "BLANCA",
	Caneca.VERDE: "VERDE",
	Caneca.NEGRA: "NEGRA",
}

const DESCRIPCION_CANECA := {
	Caneca.BLANCA: "aprovechables: plástico, vidrio, metal, papel y cartón",
	Caneca.VERDE: "orgánicos aprovechables: restos de comida y poda",
	Caneca.NEGRA: "no aprovechables: servilletas, metalizados, icopor",
}

const COLOR_CANECA := {
	Caneca.BLANCA: Color(0.95, 0.95, 0.97),
	Caneca.VERDE: Color(0.45, 0.85, 0.45),
	Caneca.NEGRA: Color(0.62, 0.62, 0.7),
}

## Cada residuo: nombre visible, caneca correcta y cuadro dentro de Assets/residuos.png
const RESIDUOS := [
	{ "nombre": "Botella plástica", "caneca": Caneca.BLANCA, "cuadro": 0 },
	{ "nombre": "Lata", "caneca": Caneca.BLANCA, "cuadro": 1 },
	{ "nombre": "Botella de vidrio", "caneca": Caneca.BLANCA, "cuadro": 2 },
	{ "nombre": "Periódico", "caneca": Caneca.BLANCA, "cuadro": 3 },
	{ "nombre": "Caja de cartón", "caneca": Caneca.BLANCA, "cuadro": 4 },
	{ "nombre": "Cáscara de banano", "caneca": Caneca.VERDE, "cuadro": 5 },
	{ "nombre": "Corazón de manzana", "caneca": Caneca.VERDE, "cuadro": 6 },
	{ "nombre": "Pulpa de café", "caneca": Caneca.VERDE, "cuadro": 7 },
	{ "nombre": "Cáscaras de huevo", "caneca": Caneca.VERDE, "cuadro": 8 },
	{ "nombre": "Hojas y poda", "caneca": Caneca.VERDE, "cuadro": 9 },
	{ "nombre": "Servilleta usada", "caneca": Caneca.NEGRA, "cuadro": 10 },
	{ "nombre": "Empaque metalizado", "caneca": Caneca.NEGRA, "cuadro": 11 },
	{ "nombre": "Icopor sucio", "caneca": Caneca.NEGRA, "cuadro": 12 },
	{ "nombre": "Tapabocas", "caneca": Caneca.NEGRA, "cuadro": 13 },
]

## La bolsa plástica no aparece al azar: es lo que deja la "bolsa voladora"
## (enemigo del nivel 2) al ser atrapada. Limpia y seca va en la caneca blanca.
const RESIDUO_BOLSA := { "nombre": "Bolsa plástica", "caneca": Caneca.BLANCA, "cuadro": 14 }

## Datos educativos que se muestran al terminar la partida.
const DATOS := [
	"Desde 2021 en Colombia los residuos se separan en tres colores: blanco, verde y negro (Resolución 2184 de 2019).",
	"El plástico, el vidrio, los metales, el papel y el cartón van limpios y secos en la caneca blanca.",
	"Las cáscaras, los restos de comida cruda y la poda van en la caneca verde y se pueden convertir en compost.",
	"Las servilletas y el papel higiénico usados van en la caneca negra: no se pueden aprovechar.",
	"La pulpa del café es un residuo orgánico: en las fincas cafeteras de Caldas se usa para hacer abono.",
	"Una botella de plástico puede tardar cientos de años en degradarse en la naturaleza.",
	"Las pilas y los aparatos electrónicos no van en ninguna caneca: llévalos a un punto posconsumo.",
	"Una mancha de aceite sobre el agua dificulta que entren la luz y el oxígeno que necesitan los peces.",
]


## Devuelve un residuo al azar del catálogo.
static func residuo_aleatorio() -> Dictionary:
	return RESIDUOS.pick_random()


static func nombre_caneca(tipo: int) -> String:
	return NOMBRES_CANECA.get(tipo, "?")


static func descripcion_caneca(tipo: int) -> String:
	return DESCRIPCION_CANECA.get(tipo, "")


static func dato_aleatorio() -> String:
	return DATOS.pick_random()


## Calificación de 0 a 3 estrellas.
## 1 estrella por ganar, 2 si además la contaminación final es menor al 50 %,
## y 3 si además la precisión al clasificar es de al menos 85 %.
static func calcular_estrellas(gano: bool, contaminacion_final: float, precision: float) -> int:
	if not gano:
		return 0
	var estrellas := 1
	if contaminacion_final < 50.0:
		estrellas += 1
		if precision >= 0.85:
			estrellas += 1
	return estrellas
