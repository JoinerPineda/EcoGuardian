"""Genera el arte agregado en la versión 2 de EcoGuardián: baldosas del pueblo
(nivel 2), casas coloniales, bolsa voladora, residuo "bolsa plástica", ícono de
sonido, nubes y logo. Los fondos de la portada están en generar_portadas.py.

Uso (DESPUÉS de generar_arte.py, porque amplía tileset.png y residuos.png):
    python3 generar_arte.py        ../../../Assets
    python3 generar_arte_nivel2.py ../../../Assets
Requiere Pillow. Respeta la paleta y el contorno (#1c1826) del arte original.
"""
import sys, random, math
from PIL import Image

ASSETS = sys.argv[1]
K = (0x1c, 0x18, 0x26, 255)  # contorno


def hexa(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def dibujar(img, ox, oy, filas, paleta):
    ancho = max(len(f) for f in filas)
    assert all(len(f) == ancho for f in filas), [len(f) for f in filas]
    for y, fila in enumerate(filas):
        for x, c in enumerate(fila):
            if c != '.' and c != ' ':
                img.putpixel((ox + x, oy + y), paleta[c])


PAL = {
    'k': K, 'W': hexa('ffffff'), 'w': hexa('f2ece0'), 'g': hexa('d3cbbb'), 'G': hexa('b9b3a6'),
    'd': hexa('8e887d'), 'D': hexa('5e5a52'),
    'r': hexa('c4553a'), 'R': hexa('8f3426'), 'o': hexa('e0785a'),
    'b': hexa('3f7fbf'), 'B': hexa('2a5a8a'), 'c': hexa('78c8e6'), 'C': hexa('c8e8f6'),
    'v': hexa('2f9e6a'), 'V': hexa('1f6e48'), 'p': hexa('5da13f'), 'P': hexa('3d7a34'),
    'y': hexa('fadc50'), 'Y': hexa('d0a030'), 'm': hexa('a8743e'), 'M': hexa('6e4826'),
    'l': hexa('c49a63'), 't': hexa('c8643c'), 'T': hexa('8c4028'), 'f': hexa('ff9ad0'),
    'x': hexa('dc3c3c'), 'e': hexa('e8e4f4', 235), 'E': hexa('b8c4dc', 235), 'i': hexa('ffffff', 200),
}

# =============================================================== TILESET
tileset = Image.open(f'{ASSETS}/tileset.png').convert('RGBA')
if tileset.size != (128, 64):
    raise SystemExit('tileset.png ya fue modificado (se esperaba 128x64)')
nuevo = Image.new('RGBA', (128, 80), (0, 0, 0, 0))
nuevo.paste(tileset, (0, 0))
tileset = nuevo
T = 16


def celda(cx, cy):
    return cx * T, cy * T


def adoquin():
    """Calle de piedra (adoquines redondeados, se repite sin cortes)."""
    img = Image.new('RGBA', (16, 16), hexa('6f6a60'))
    rnd = random.Random(4)
    tonos = [hexa('a39c8e'), hexa('b0a999'), hexa('978f80')]
    for fila in range(4):
        y0 = fila * 4
        desplazamiento = 0 if fila % 2 == 0 else 3
        x = -desplazamiento
        while x < 16:
            ancho = 5 if (x + fila) % 2 == 0 else 6
            tono = rnd.choice(tonos)
            for yy in range(y0, y0 + 3):
                for xx in range(x, x + ancho - 1):
                    esquina = (yy in (y0, y0 + 2)) and (xx in (x, x + ancho - 2))
                    if esquina:
                        continue
                    img.putpixel((xx % 16, yy), tono)
            img.putpixel(((x + 1) % 16, y0), hexa('c9c2b3'))
            img.putpixel(((x + ancho - 3) % 16, y0 + 2), hexa('8a8478'))
            x += ancho
    return img


def anden():
    """Andén de baldosas claras."""
    img = Image.new('RGBA', (16, 16), hexa('d8cfbb'))
    for i in range(16):
        img.putpixel((i, 0), hexa('b8ae98'))
        img.putpixel((i, 8), hexa('b8ae98'))
        img.putpixel((0, i), hexa('b8ae98'))
        img.putpixel((8, i), hexa('b8ae98'))
    rnd = random.Random(7)
    for _ in range(10):
        img.putpixel((rnd.randrange(16), rnd.randrange(16)), hexa('cbc1ab'))
    for (x, y) in [(1, 1), (9, 1), (1, 9), (9, 9)]:
        img.putpixel((x, y), hexa('e8e0cc'))
    return img


def malecon():
    """Malecón de ladrillo junto al río."""
    img = Image.new('RGBA', (16, 16), hexa('7a3e26'))
    for fila in range(4):
        y0 = fila * 4
        desplazamiento = 0 if fila % 2 == 0 else 4
        for b in range(-1, 3):
            x0 = b * 8 + desplazamiento
            tono = hexa('b0603c') if (b + fila) % 2 == 0 else hexa('c06c44')
            for yy in range(y0, y0 + 3):
                for xx in range(x0, x0 + 7):
                    if 0 <= xx < 16:
                        img.putpixel((xx, yy), tono)
            for xx in range(x0, x0 + 7):
                if 0 <= xx < 16:
                    img.putpixel((xx, y0), hexa('d08a5c'))
    return img


tileset.paste(adoquin(), celda(7, 0))
tileset.paste(anden(), celda(4, 1))
tileset.paste(malecon(), celda(5, 1))
# Puente para río vertical: los tablones del puente original, girados
puente_izq = tileset.crop((2 * T, 1 * T, 3 * T, 2 * T))
puente_der = tileset.crop((3 * T, 1 * T, 4 * T, 2 * T))
tileset.paste(puente_izq.rotate(-90), celda(6, 1))  # baranda arriba
tileset.paste(puente_der.rotate(-90), celda(7, 1))  # baranda abajo

# Guayacán amarillo (1x2): el árbol original con la copa recoloreada
arbol = tileset.crop((0, 2 * T, T, 4 * T))
mapa_color = {
    hexa('5da13f'): hexa('f6c83a'), hexa('347838'): hexa('c88a1c'), hexa('3d7a34'): hexa('d49a22'),
    hexa('56a24a'): hexa('fadc50'), hexa('2c6a30'): hexa('a86e14'),
}
guayacan = Image.new('RGBA', arbol.size)
for y in range(arbol.height):
    for x in range(arbol.width):
        p = arbol.getpixel((x, y))
        if p[3] == 0:
            continue
        r, g, b, a = p
        if g > r and g > b and y < 22:  # verdes de la copa
            brillo = (r + g + b) / 3
            if brillo > 110:
                p = hexa('fadc50')
            elif brillo > 80:
                p = hexa('f0b830')
            else:
                p = hexa('c88a1c')
        guayacan.putpixel((x, y), p)
tileset.paste(guayacan, celda(6, 2))

FAROL = [
    "......kkkk......",
    ".....kyyyyk.....",
    "....kkkkkkkk....",
    "....kyyWyyyk....",
    "....kyWyyyyk....",
    "....kyyyyyyk....",
    "....kkkkkkkk....",
    ".....kkkkkk.....",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    ".......kk.......",
    "......kkkk......",
    ".....kkkkkk.....",
    ".....kDDDDk.....",
    "......dddd......",
    "................",
    "................",
    "................",
]
dibujar(tileset, 7 * T, 2 * T, FAROL, PAL)

MATERA = [
    "................",
    "....kk....kk....",
    "...kffk..kxxk...",
    "...kfyfkkxyxk...",
    "....kfkpkkxk....",
    "..kk.kpPpkk.kk..",
    ".kffkkpPPpkkyyk.",
    ".kfyfpPpPpPkyWk.",
    "..kkpPpPpPpPkk..",
    "..kkkkkkkkkkkk..",
    "..kooooooooook..",
    "...ktttttttttk..",
    "...ktttttttttk..",
    "....kTTTTTTTk...",
    ".....kkkkkkk....",
    "......ddddd.....",
]
dibujar(tileset, 3 * T, 3 * T, MATERA, PAL)

BANCA = [
    "................",
    "................",
    "................",
    "kkkkkkkkkkkkkkkk",
    "kllllllllllllllk",
    "kmmmmmmmmmmmmmmk",
    "kkkkkkkkkkkkkkkk",
    "kllllllllllllllk",
    "kmmmmmmmmmmmmmmk",
    "kkkkkkkkkkkkkkkk",
    ".kk.........kk..",
    ".kk.........kk..",
    ".kk.........kk..",
    ".kk.........kk..",
    ".dd.........dd..",
    "................",
]
dibujar(tileset, 2 * T, 3 * T, BANCA, PAL)

FUENTE_AGUA = [  # pila de la plaza (fuente)
    "................",
    "......kkkk......",
    ".....kccCck.....",
    "......kbbk......",
    "...kkkkkkkkkk...",
    "..kGccccccccGk..",
    ".kGcCccccbccGGk.",
    ".kGcccbccccccGk.",
    ".kgGccccccCcGgk.",
    ".kggGGGGGGGGggk.",
    ".kgggggggggggggk",
    "..kGGGGGGGGGGk..",
    "...kkkkkkkkkk...",
    "....dddddddd....",
    "................",
    "................",
]
FUENTE_AGUA = [f[:16] for f in FUENTE_AGUA]
dibujar(tileset, 4 * T, 3 * T, FUENTE_AGUA, PAL)
tileset.save(f'{ASSETS}/tileset.png')

# =============================================================== CASAS DEL PUEBLO
casa = Image.open(f'{ASSETS}/casa.png').convert('RGBA')
variantes = [
    # (puertas/ventanas, oscuro, zócalo, zócalo oscuro, techo)
    (hexa('c83c46'), hexa('8a2430'), hexa('3f7fbf'), hexa('2a5a8a'), None),
    (hexa('2f9e6a'), hexa('1f6e48'), hexa('e0a030'), hexa('a87018'), None),
    (hexa('f0c040'), hexa('b08820'), hexa('b4508c'), hexa('7c3060'), None),
]
casas = Image.new('RGBA', (48 * 3, 48))
for i, (puerta, puerta_osc, zocalo, zocalo_osc, _) in enumerate(variantes):
    copia = casa.copy()
    for y in range(48):
        for x in range(48):
            p = copia.getpixel((x, y))
            if p[3] == 0:
                continue
            q = p
            if p == hexa('3f7fbf'):
                q = puerta
            elif p == hexa('2a5a8a'):
                q = puerta_osc
            elif p == hexa('2f9e6a'):
                q = zocalo
            elif p == hexa('1f6e48'):
                q = zocalo_osc
            copia.putpixel((x, y), q)
    if i == 1:
        # Balcón de madera bajo las ventanas (típico de Salamina y Aguadas)
        for x in range(4, 44):
            copia.putpixel((x, 30), K)
            copia.putpixel((x, 33), hexa('6e4826'))
            if x % 3 == 0:
                copia.putpixel((x, 31), hexa('6e4826'))
                copia.putpixel((x, 32), hexa('6e4826'))
    casas.paste(copia, (i * 48, 0))
casas.save(f'{ASSETS}/casas_pueblo.png')

# =============================================================== BOLSA VOLADORA (enemigo)
BOLSA_BASE = [
    "................",
    "...kk......kk...",
    "..k.ek....ke.k..",
    "..k..k....k..k..",
    "...k.kkkkkk.k...",
    "...keeeeeeeek...",
    "..keeeeieeeeek..",
    "..keekkeekkeek..",
    "..keekWeekWeek..",
    ".keeeeeeeeeeeek.",
    ".keEeeekkeeeEek.",
    ".keEeeeeeeeeEek.",
    "..keEEeeeeEEek..",
    "..kEkEEkkEEkEk..",
    "...k.kk..kk.k...",
    "................",
]


def desplazar_filas(filas, offsets):
    resultado = []
    for y, fila in enumerate(filas):
        d = offsets.get(y, 0)
        if d > 0:
            fila = '.' * d + fila[:-d]
        elif d < 0:
            fila = fila[-d:] + '.' * (-d)
        resultado.append(fila)
    return resultado


bolsa = Image.new('RGBA', (16 * 5, 16))
cuadros = [
    BOLSA_BASE,
    desplazar_filas(BOLSA_BASE, {0: 1, 1: 1, 2: 1, 3: 1, 12: -1, 13: -1, 14: -1}),
    BOLSA_BASE,
    desplazar_filas(BOLSA_BASE, {0: -1, 1: -1, 2: -1, 3: -1, 12: 1, 13: 1, 14: 1}),
]
for i, filas in enumerate(cuadros):
    dibujar(bolsa, i * 16, 0, filas, PAL)
# Cuadro de golpe: blanco brillante con ojos en X
GOLPE = [f.replace('e', 'W').replace('E', 'g').replace('i', 'W') for f in BOLSA_BASE]
GOLPE[7] = "..kWWkWWWWkWWk.."[:16]
GOLPE[8] = "..kWWWkWWkWWWk.."[:16]
dibujar(bolsa, 4 * 16, 0, GOLPE, PAL)
bolsa.save(f'{ASSETS}/bolsa.png')

# Residuo "bolsa plástica" (cuadro 14 de residuos.png): bolsa arrugada en el suelo
residuos = Image.open(f'{ASSETS}/residuos.png').convert('RGBA')
if residuos.width == 224:
    ampliado = Image.new('RGBA', (240, 16))
    ampliado.paste(residuos, (0, 0))
    BOLSA_SUELO = [
        "................",
        "................",
        "................",
        "....kk...kk.....",
        "...k.ek.ke.k....",
        "...k..kkk..k....",
        "....keeeeek.....",
        "...keeeieeek....",
        "..keeeeeeeEek...",
        "..keEeeeeeeEk...",
        "..keeEeeeEeek...",
        "...kEEeeeEEk....",
        "....kkkkkkk.....",
        "................",
        "................",
        "................",
    ]
    dibujar(ampliado, 14 * 16, 0, BOLSA_SUELO, PAL)
    ampliado.save(f'{ASSETS}/residuos.png')

# =============================================================== ÍCONO DE SONIDO (2 cuadros de 12x12)
SONIDO = [
    "............",
    ".....k......",
    "....kk...k..",
    "...kWk.k..k.",
    "kkkWWk..k.k.",
    "kWWWWk..k.k.",
    "kWWWWk..k.k.",
    "kkkWWk..k.k.",
    "...kWk.k..k.",
    "....kk...k..",
    ".....k......",
    "............",
]
MUDO = [
    "............",
    ".....k......",
    "....kk......",
    "...kWk......",
    "kkkWWk.x...x",
    "kWWWWk..x.x.",
    "kWWWWk...x..",
    "kkkWWk..x.x.",
    "...kWk.x...x",
    "....kk......",
    ".....k......",
    "............",
]
icono = Image.new('RGBA', (24, 12))
pal_icono = dict(PAL)
pal_icono['k'] = hexa('f2ece0')
pal_icono['W'] = hexa('f2ece0')
dibujar(icono, 0, 0, SONIDO, pal_icono)
dibujar(icono, 12, 0, MUDO, pal_icono)
icono.save(f'{ASSETS}/sonido.png')

# El fondo de la portada lo genera generar_portadas.py (5 estilos)

# Nubes (2 cuadros de 48x16)
nubes = Image.new('RGBA', (96, 16))
for i, (ancho, bultos) in enumerate([(44, [(10, 9, 7), (20, 7, 8), (31, 9, 6)]), (36, [(9, 9, 6), (19, 8, 7), (28, 10, 5)])]):
    for y in range(16):
        for x in range(48):
            dentro = y >= 9 and y <= 12 and 3 <= x <= ancho
            for (bx, by, r) in bultos:
                if math.hypot(x - bx, y - by) <= r:
                    dentro = True
            if dentro and y <= 12:
                c = hexa('ffffff') if y < 9 else hexa('dfe9f2')
                nubes.putpixel((i * 48 + x, y), c)
nubes.save(f'{ASSETS}/nubes.png')

# Logo: hoja con una gota (24x24)
LOGO = [
    "...........kkk..........",
    ".........kkpppk.........",
    "........kpppppPk........",
    ".......kppWpppPPk.......",
    "......kpppWppppPk.......",
    "......kppppWpppPPk......",
    ".....kpppppkppppPk......",
    ".....kppppppkpppPPk.....",
    ".....kpppppppkpppPk.....",
    ".....kPpppppppkppPk.....",
    "......kPppppppkkpPk.....",
    "......kPPppppppkkPk.....",
    ".......kPPpppppppkk.....",
    "........kPPPpppPPk......",
    ".........kkPPPPkk.......",
    "...........kMk..........",
    "...........kMk....kk....",
    "..........kMk....kcck...",
    "..........kk....kcCcck..",
    "...............kcCcccck.",
    "...............kccccBck.",
    "................kcBBck..",
    ".................kkkk...",
    "........................",
]
logo = Image.new('RGBA', (24, 24))
dibujar(logo, 0, 0, LOGO, PAL)
logo.save(f'{ASSETS}/logo.png')
print('arte generado')
