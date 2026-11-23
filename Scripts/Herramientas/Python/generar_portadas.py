"""Genera los 5 fondos de portada de EcoGuardián (320x180 cada uno):
  portada_1.png  Amanecer en el Nevado del Ruiz
  portada_2.png  Atardecer cafetero (sol retro y palmas)
  portada_3.png  Noche de luciérnagas (luna y estrellas)
  portada_4.png  Valle de Cocora (palmas de cera, el árbol nacional)
  portada_5.png  El pueblo (casas coloniales y catedral)
La franja de abajo (y >= 112) la tapa el paisaje de baldosas del menú.
El estilo se elige en el nodo MenuPrincipal (propiedad "Estilo Portada").

Uso: python3 generar_portadas.py ../../../Assets      (requiere Pillow)
"""
import sys, math, random
from PIL import Image

ASSETS = sys.argv[1]
W, H = 320, 180
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def hexa(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def cielo(img, colores, hasta=110):
    """Degradado vertical con tramado (dithering) para conservar el pixel art."""
    for y in range(H):
        t = min(y / float(hasta), 0.999) * (len(colores) - 1)
        i = int(t)
        f = t - i
        for x in range(W):
            img.putpixel((x, y), colores[i + 1] if f * 16 > BAYER[y % 4][x % 4] + 0.5 else colores[i])


def relleno_bajo(img, perfil, color, borde=None, franjas=None):
    """Pinta una silueta: todo lo que está debajo de perfil(x)."""
    for x in range(W):
        h = int(perfil(x))
        for y in range(max(h, 0), H):
            c = color
            if franjas and ((x // 2) + (y - h) * 2) % 6 == 0:
                c = franjas
            img.putpixel((x, y), c)
        if borde is not None and 0 <= h < H:
            img.putpixel((x, h), borde)


def disco(img, cx, cy, r, color, borde=None, cortes=None):
    for y in range(int(cy - r - 2), int(cy + r + 3)):
        for x in range(int(cx - r - 2), int(cx + r + 3)):
            if not (0 <= x < W and 0 <= y < H):
                continue
            d = math.hypot(x - cx, y - cy)
            if d < r:
                if cortes and cortes(y):
                    continue
                img.putpixel((x, y), color(y) if callable(color) else color)
            elif borde and d < r + 2 and (x + y) % 2 == 0:
                img.putpixel((x, y), borde)


def palma_de_cera(img, x0, base, alto, tronco, hoja, hoja_osc):
    """Palma de cera del Quindío: tronco muy delgado y alto con un penacho arriba."""
    for y in range(base - alto, base):
        img.putpixel((x0, y), tronco)
        if (y // 3) % 2 == 0:
            img.putpixel((x0 + 1, y), tronco)
    cy = base - alto
    for angulo in range(0, 360, 30):
        a = math.radians(angulo)
        largo = 7 if math.sin(a) < 0.3 else 5
        for paso in range(1, largo):
            x = int(round(x0 + math.cos(a) * paso))
            y = int(round(cy + math.sin(a) * paso * 0.6 + (paso * paso) * 0.08))
            if 0 <= x < W and 0 <= y < H:
                img.putpixel((x, y), hoja if paso < largo - 2 else hoja_osc)


def casitas(img, puntos):
    for cx, cy in puntos:
        for y in range(cy, cy + 3):
            for x in range(cx, cx + 4):
                img.putpixel((x, y), hexa('f2ece0'))
        for x in range(cx, cx + 4):
            img.putpixel((x, cy - 1), hexa('c4553a'))


def nevado(x, centro=92):
    base = 88 + 6 * math.sin(x * 0.035) + 3 * math.sin(x * 0.11 + 1.0)
    return base - 40 * math.exp(-((x - centro) / 46.0) ** 2)


def pintar_nevado(img, roca, roca2, nieve, nieve_sombra, contorno, centro=92):
    for x in range(W):
        h = int(nevado(x, centro))
        for y in range(h, H):
            limite = 60 + 3 * math.sin(x * 0.4) + (2 if x % 7 == 0 else 0)
            if y < limite and abs(x - centro) < 46:
                c = nieve if x < centro + 4 + (y - h) * 0.2 else nieve_sombra
            else:
                c = roca if (x + y) % 2 == 0 or y > h + 3 else roca2
            img.putpixel((x, y), c)
        if 0 <= h < H:
            img.putpixel((x, h), contorno)


# ================================================================= 1. AMANECER EN EL NEVADO
def portada_1():
    img = Image.new('RGBA', (W, H))
    cielo(img, [hexa(c) for c in ['2d5a9c', '3f78b8', '5f9ad0', '8cc0e0', 'c4ddd8', 'f4d8a0']])
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - 250, y - 58)
            if d < 11:
                img.putpixel((x, y), hexa('fff2b0'))
            elif d < 13 and (x + y) % 2 == 0:
                img.putpixel((x, y), hexa('ffe08a'))
    pintar_nevado(img, hexa('6c80a8'), hexa('7a8eb4'), hexa('f4f6ff'), hexa('c4cee6'), hexa('4a5a80'))
    relleno_bajo(img, lambda x: 98 + 8 * math.sin(x * 0.03 + 2.0) + 4 * math.sin(x * 0.09),
                 hexa('3f7f5a'), hexa('285a3c'), hexa('2f6a48'))
    relleno_bajo(img, lambda x: 106 + 5 * math.sin(x * 0.05 + 4.0), hexa('2c5e3e'), hexa('22482f'))
    casitas(img, [(196, 101), (203, 99), (210, 102), (224, 104), (40, 103)])
    return img


# ================================================================= 2. ATARDECER CAFETERO
def portada_2():
    img = Image.new('RGBA', (W, H))
    cielo(img, [hexa(c) for c in ['1e1442', '3c1f5e', '7a2e6e', 'c4506a', 'f08a4c', 'ffc66e']], 104)
    # Sol grande con franjas (estilo retro)
    def color_sol(y):
        t = (y - 52) / 50.0
        return hexa('ffe68a') if t < 0.4 else (hexa('ffb84a') if t < 0.7 else hexa('ff8a4a'))
    disco(img, 160, 96, 38, color_sol, cortes=lambda y: y > 78 and (y - 78) % 6 < 1 + (y - 78) // 8)
    relleno_bajo(img, lambda x: 90 + 7 * math.sin(x * 0.04 + 1.0) + 3 * math.sin(x * 0.13), hexa('8a3a6e'), hexa('6a2a5a'))
    relleno_bajo(img, lambda x: 99 + 6 * math.sin(x * 0.035 + 3.0) + 2 * math.sin(x * 0.1),
                 hexa('4e2452'), hexa('3a1a42'), hexa('431e4a'))
    relleno_bajo(img, lambda x: 107 + 4 * math.sin(x * 0.06), hexa('2a1636'), hexa('1e0f28'))
    for x0, alto in [(28, 58), (46, 44), (268, 54), (290, 66), (304, 40)]:
        palma_de_cera(img, x0, 112, alto, hexa('1a0e24'), hexa('1a0e24'), hexa('24122e'))
    # Pájaros
    for bx, by in [(120, 40), (130, 36), (138, 42), (210, 30)]:
        for dx, dy in [(-2, -1), (-1, 0), (1, 0), (2, -1)]:
            img.putpixel((bx + dx, by + dy), hexa('2a1636'))
    return img


# ================================================================= 3. NOCHE DE LUCIÉRNAGAS
def portada_3():
    img = Image.new('RGBA', (W, H))
    cielo(img, [hexa(c) for c in ['070a22', '0e1636', '18244e', '22386a', '2e4a7a']], 110)
    rnd = random.Random(21)
    for _ in range(140):
        x, y = rnd.randrange(W), rnd.randrange(0, 80)
        img.putpixel((x, y), hexa('ffffff') if rnd.random() < 0.6 else hexa('fff2a0'))
    for x, y in [(40, 20), (150, 14), (205, 40), (300, 22)]:  # estrellas grandes
        for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
            img.putpixel((x + dx, y + dy), hexa('ffffff'))
    # Luna creciente
    disco(img, 252, 34, 13, hexa('fff6d0'), borde=hexa('c8d4f0'))
    disco(img, 258, 30, 12, lambda y: img.getpixel((0, y)))
    pintar_nevado(img, hexa('2a3a62'), hexa('324470'), hexa('c8d4f0'), hexa('8e9cc4'), hexa('1a2648'))
    relleno_bajo(img, lambda x: 98 + 8 * math.sin(x * 0.03 + 2.0) + 4 * math.sin(x * 0.09),
                 hexa('1e3a3e'), hexa('142a2e'), hexa('19333a'))
    relleno_bajo(img, lambda x: 106 + 5 * math.sin(x * 0.05 + 4.0), hexa('132a28'), hexa('0c1e1c'))
    # Ventanas encendidas a lo lejos
    for cx, cy in [(196, 101), (203, 99), (210, 102), (224, 104), (40, 103)]:
        img.putpixel((cx + 1, cy + 1), hexa('ffd860'))
        img.putpixel((cx + 2, cy + 1), hexa('ffd860'))
    return img


# ================================================================= 4. VALLE DE COCORA
def portada_4():
    img = Image.new('RGBA', (W, H))
    cielo(img, [hexa(c) for c in ['3e8ed8', '5fa8e4', '8cc6ee', 'bfe2f4', 'e6f4f4']], 100)
    # Nubes pintadas
    for cx, cy, r in [(60, 30, 9), (72, 26, 11), (86, 31, 8), (210, 20, 8), (222, 16, 10), (236, 21, 8)]:
        disco(img, cx, cy, r, hexa('ffffff'))
    for x in range(50, 96):
        img.putpixel((x, 38), hexa('dbe8f2'))
    # Montañas empinadas en capas, con neblina entre ellas
    relleno_bajo(img, lambda x: 62 + 18 * math.sin(x * 0.045) + 6 * math.sin(x * 0.12 + 2.0), hexa('7fb08e'), hexa('6a9c7a'))
    # Neblina suave sobre las montañas lejanas (tramado ralo, no líneas)
    for y in range(60, 92):
        for x in range(W):
            p = img.getpixel((x, y))
            if p[1] > p[2] and BAYER[y % 4][x % 4] < 2:
                img.putpixel((x, y), hexa('cfe6dc'))
    relleno_bajo(img, lambda x: 82 + 12 * math.sin(x * 0.05 + 1.5) + 4 * math.sin(x * 0.15), hexa('4e9a52'), hexa('3c8040'), hexa('468e4a'))
    relleno_bajo(img, lambda x: 100 + 6 * math.sin(x * 0.04 + 3.0), hexa('3a7e3a'), hexa('2c6a2e'))
    rnd = random.Random(5)
    for x0 in [18, 34, 52, 70, 96, 118, 196, 214, 236, 252, 278, 296, 310]:
        base = int(100 + 6 * math.sin(x0 * 0.04 + 3.0)) + 2
        palma_de_cera(img, x0, base, rnd.randint(34, 60), hexa('d8d4c8'), hexa('3c8a3c'), hexa('2a6a2a'))
    return img


# ================================================================= 5. EL PUEBLO
def portada_5():
    img = Image.new('RGBA', (W, H))
    cielo(img, [hexa(c) for c in ['4a86c8', '6aa2d8', '96c2e6', 'c8e0ee', 'f0e6c8']], 96)
    for cx, cy, r in [(40, 24, 7), (50, 21, 9), (61, 25, 6), (262, 34, 6), (272, 31, 8)]:
        disco(img, cx, cy, r, hexa('ffffff'))
    relleno_bajo(img, lambda x: 66 + 10 * math.sin(x * 0.03 + 0.5) + 4 * math.sin(x * 0.1), hexa('5c8a6a'), hexa('4a7458'), hexa('52806a'))
    relleno_bajo(img, lambda x: 80 + 6 * math.sin(x * 0.05 + 2.0), hexa('3f7f4a'), hexa('2e663a'), hexa('367240'))
    k = hexa('1c1826')
    blanco, sombra = hexa('f2ece0'), hexa('d3cbbb')
    techo, techo2 = hexa('c4553a'), hexa('8f3426')
    colores = [hexa('c83c46'), hexa('3f7fbf'), hexa('2f9e6a'), hexa('f0c040'), hexa('b4508c')]

    def rect(x0, y0, x1, y1, c):
        for y in range(max(y0, 0), min(y1, H)):
            for x in range(max(x0, 0), min(x1, W)):
                img.putpixel((x, y), c)

    # Hilera de casas a los dos lados (la catedral se dibuja después, encima)
    cx = 258
    x = 2
    i = 0
    while x < W - 4:
        ancho = 26 + (i % 3) * 4
        if x + ancho > cx - 24 and x < cx + 24:   # deja libre el lugar de la catedral
            x = cx + 24
            continue
        alto = 22 + (i % 2) * 6
        y0 = 112 - alto
        rect(x, y0, x + ancho, 112, blanco if i % 2 == 0 else sombra)
        rect(x - 1, y0 - 4, x + ancho + 1, y0, techo)
        rect(x - 1, y0 - 1, x + ancho + 1, y0, techo2)
        c = colores[i % len(colores)]
        rect(x + 3, y0 + 4, x + 8, y0 + 10, c)                  # ventanas
        rect(x + ancho - 8, y0 + 4, x + ancho - 3, y0 + 10, c)
        rect(x + ancho // 2 - 3, 112 - 12, x + ancho // 2 + 3, 112, c)  # puerta
        if i % 2 == 1:                                          # balcón
            rect(x + 1, y0 + 11, x + ancho - 1, y0 + 12, hexa('6e4826'))
        rect(x, 109, x + ancho, 112, colores[(i + 2) % len(colores)])   # zócalo
        x += ancho + 2
        i += 1
    # Catedral con dos torres (como las de los pueblos de Caldas), a la derecha
    # para que no la tapen el título ni los botones del menú
    cx, dy = 258, 20
    rect(cx - 22, 64 + dy, cx + 22, 112, blanco)
    rect(cx - 22, 64 + dy, cx + 22, 65 + dy, k)
    for tx in (cx - 22, cx + 12):
        rect(tx, 40 + dy, tx + 10, 112, blanco)
        rect(tx, 40 + dy, tx + 1, 112, k)
        rect(tx + 9, 40 + dy, tx + 10, 112, k)
        rect(tx + 3, 47 + dy, tx + 7, 54 + dy, hexa('3a3048'))  # campanario
        for y in range(30 + dy, 40 + dy):                       # cúpula
            ancho = (y - 30 - dy) // 2
            rect(tx + 5 - ancho, y, tx + 5 + ancho + 1, y + 1, techo)
        rect(tx + 4, 25 + dy, tx + 6, 30 + dy, hexa('d0a030'))  # cruz
        rect(tx + 3, 26 + dy, tx + 7, 27 + dy, hexa('d0a030'))
    rect(cx - 10, 60 + dy, cx + 10, 64 + dy, techo)
    for y in range(52 + dy, 60 + dy):                           # frontón
        ancho = (y - 52 - dy) + 2
        rect(cx - ancho, y, cx + ancho, y + 1, techo)
    rect(cx - 5, 98, cx + 5, 112, hexa('6e4826'))               # puerta
    rect(cx - 4, 88, cx + 4, 94, hexa('3f7fbf'))                 # rosetón
    # Guayacanes amarillos delante
    for gx in (30, 112, 196):
        disco(img, gx, 98, 8, hexa('f6c83a'), borde=hexa('c88a1c'))
        rect(gx - 1, 104, gx + 1, 112, hexa('6e4826'))
    return img


for numero, funcion in enumerate([portada_1, portada_2, portada_3, portada_4, portada_5], start=1):
    funcion().save(f'{ASSETS}/portada_{numero}.png')
print('portadas generadas')
