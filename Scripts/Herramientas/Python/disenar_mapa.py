#!/usr/bin/env python3
"""Diseña el mapa ASCII de 48x30 y lo imprime (se copia al constructor del mapa)."""
import random
AN, AL = 48, 30
m = [["." for _ in range(AN)] for _ in range(AL)]


def poner(x, y, c):
    if 0 <= x < AN and 0 <= y < AL:
        m[y][x] = c


# --- río serpenteante (3 celdas de ancho)
centro = {}
for x in range(AN):
    if x <= 6: yc = 6
    elif x <= 11: yc = 6 + (x - 6)        # baja hasta 11
    elif x <= 24: yc = 12 if x >= 12 else 11
    elif x <= 29: yc = 12 - (x - 24)      # sube hasta 7
    elif x <= 36: yc = 7
    elif x <= 41: yc = 7 + (x - 36)       # baja hasta 12
    else: yc = 12
    centro[x] = yc
    for dy in (-1, 0, 1):
        poner(x, yc + dy, "~")
    # en los tramos diagonales se agrega una celda extra para que el agua no se corte
    if x > 0 and centro[x - 1] != yc:
        poner(x, centro[x - 1] + (1 if centro[x - 1] > yc else -1), "~")

# --- bordes
for x in range(AN):
    for y in (0, AL - 1):
        if m[y][x] != "~": m[y][x] = "#"
for y in range(AL):
    for x in (0, AN - 1):
        if m[y][x] != "~": m[y][x] = "#"
# esquinas y bordes más gruesos en algunos tramos
for (x, y) in [(1, 1), (46, 1), (1, 28), (46, 28), (2, 28), (45, 28), (1, 27), (46, 27)]:
    poner(x, y, "#")

# --- camino norte-sur con puente (x = 17, 18)
for y in range(1, AL - 1):
    for x in (17, 18):
        if m[y][x] == "~":
            m[y][x] = "B"
        elif 7 <= y <= 17:
            m[y][x] = "="

# --- casa (huella 3x3; 'H' = esquina inferior central) y camino a la puerta
for y in range(4, 7):
    for x in range(19, 22):
        poner(x, y, "h")
poner(20, 6, "H")
for x in range(19, 22):
    poner(x, 7, "=")

# --- cafetal (surcos) al noroeste de la casa
for y in (2, 4, 6, 8):
    for x in range(10, 16):
        if m[y][x] == "." and (x + y) % 5 != 0:
            poner(x, y, "c")
for x in range(18, 23):
    if m[3][x] == ".":
        poner(x, 3, "f")

# --- plaza con canecas
for y in range(18, 24):
    for x in range(14, 23):
        poner(x, y, "P")
poner(16, 19, "b"); poner(18, 19, "v"); poner(20, 19, "n")
poner(18, 22, "S")
for x in range(14, 23, 8):
    poner(x, 18, "r")

# --- caminos este y oeste desde la plaza
for x in range(4, 14):
    poner(x, 21, "=")
for x in range(23, 44):
    if m[21][x] == ".": poner(x, 21, "=")
for y in range(14, 21):
    if m[y][38] == ".": poner(38, y, "=")

# --- estanque al suroeste
for y in range(15, 21):
    for x in range(2, 10):
        dx = (x - 5.5) / 3.6
        dy = (y - 17.5) / 2.8
        if dx * dx + dy * dy <= 1.0:
            poner(x, y, "o")

# --- guaduales en las orillas
for (x, y) in [(3, 9), (4, 9), (13, 14), (24, 14), (31, 9), (33, 9), (43, 14), (45, 14), (26, 4), (27, 4), (41, 6), (40, 4)]:
    if m[y][x] == ".": poner(x, y, "G")

# --- árboles dispersos
random.seed(4)
arboles = [(3, 3), (6, 2), (23, 2), (25, 8), (29, 2), (33, 3), (36, 2), (44, 3), (45, 8), (42, 9),
           (4, 24), (7, 26), (10, 23), (12, 26), (25, 25), (28, 23), (31, 27), (34, 24),
           (40, 26), (43, 23), (45, 18), (34, 16), (29, 15), (9, 13), (11, 17), (24, 17), (31, 19),
           (37, 25), (21, 26), (15, 26), (2, 12), (5, 27)]
for (x, y) in arboles:
    if m[y][x] == ".": poner(x, y, "T")
for (x, y) in [(13, 24), (26, 19), (33, 12), (7, 14), (39, 17), (44, 25), (22, 9), (8, 4)]:
    if m[y][x] == ".": poner(x, y, "r")

for fila in m:
    print("".join(fila))
