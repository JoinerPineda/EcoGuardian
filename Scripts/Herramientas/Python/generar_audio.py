#!/usr/bin/env python3
"""
Generador de efectos de sonido y música original (estilo chiptune) de "Río Limpio".
Todo se sintetiza con ondas (cuadrada, triangular, seno y ruido): no usa muestras
de terceros. Ejecuta:  python3 generar_audio.py <carpeta_Audio>
"""
import sys, os, wave
import numpy as np

SALIDA = sys.argv[1] if len(sys.argv) > 1 else "Audio"
os.makedirs(SALIDA, exist_ok=True)
FS = 22050
rng = np.random.default_rng(7)


# ------------------------------------------------------------ utilidades
def t_de(dur):
    return np.arange(int(FS * dur)) / FS


def onda(tipo, frec, dur, ciclo=0.5):
    """Genera una onda con frecuencia constante o variable (array)."""
    n = int(FS * dur)
    f = np.full(n, frec, dtype=float) if np.isscalar(frec) else np.asarray(frec, dtype=float)
    fase = np.cumsum(f) / FS
    fr = fase % 1.0
    if tipo == "cuadrada":
        return np.where(fr < ciclo, 1.0, -1.0)
    if tipo == "triangular":
        return 4.0 * np.abs(fr - 0.5) - 1.0
    if tipo == "seno":
        return np.sin(2 * np.pi * fase)
    if tipo == "ruido":
        return rng.uniform(-1, 1, n)
    raise ValueError(tipo)


def barrido(f0, f1, dur, curva=1.0):
    x = np.linspace(0, 1, int(FS * dur)) ** curva
    return f0 + (f1 - f0) * x


def envolvente(n, ataque=0.005, caida=0.1, sostener=0.6, liberar=0.05, dur=None):
    """ADSR sencillo."""
    a = int(FS * ataque); d = int(FS * caida); r = int(FS * liberar)
    s = max(0, n - a - d - r)
    env = np.concatenate([
        np.linspace(0, 1, max(a, 1)),
        np.linspace(1, sostener, max(d, 1)),
        np.full(s, sostener),
        np.linspace(sostener, 0, max(r, 1)),
    ])
    if len(env) < n:
        env = np.pad(env, (0, n - len(env)))
    return env[:n]


def decaer(n, rapidez=8.0):
    return np.exp(-np.linspace(0, rapidez, n))


def nota_hz(nombre):
    nombres = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    nota, octava = nombre[:-1], int(nombre[-1])
    midi = 12 * (octava + 1) + nombres[nota]
    return 440.0 * 2 ** ((midi - 69) / 12)


def concatenar(*partes):
    return np.concatenate(partes)


def guardar(nombre, senal, volumen=0.6):
    senal = np.asarray(senal, dtype=float)
    pico = np.max(np.abs(senal)) or 1.0
    senal = senal / pico * volumen
    # pequeño fundido para evitar clics
    f = min(64, len(senal) // 4)
    if f > 0:
        senal[:f] *= np.linspace(0, 1, f)
        senal[-f:] *= np.linspace(1, 0, f)
    datos = (senal * 32767).astype(np.int16)
    with wave.open(os.path.join(SALIDA, nombre + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())


def tono(nombre_nota, dur, tipo="cuadrada", ciclo=0.5, rapidez=6.0):
    s = onda(tipo, nota_hz(nombre_nota), dur, ciclo)
    return s * decaer(len(s), rapidez)


# ------------------------------------------------------------ efectos
def efectos():
    # recoger: barrido ascendente corto + destello
    a = onda("cuadrada", barrido(500, 1100, 0.07), 0.07, 0.25) * envolvente(int(FS * 0.07), caida=0.03, sostener=0.7, liberar=0.02)
    b = tono("E6", 0.08, "cuadrada", 0.25, 5)
    guardar("recoger", concatenar(a, b), 0.45)

    # acierto: arpegio mayor
    guardar("acierto", concatenar(tono("C6", 0.07), tono("E6", 0.07), tono("G6", 0.16, rapidez=4)), 0.45)

    # error: zumbido descendente con vibrato
    t = t_de(0.32)
    f = barrido(240, 110, 0.32) * (1 + 0.04 * np.sin(2 * np.pi * 18 * t))
    guardar("error", onda("cuadrada", f, 0.32, 0.4) * envolvente(len(t), caida=0.05, sostener=0.8, liberar=0.08), 0.42)

    # combo: arpegio de cuatro notas + brillo
    combo = concatenar(tono("C6", 0.06), tono("E6", 0.06), tono("G6", 0.06), tono("C7", 0.22, rapidez=3))
    brillo = onda("seno", 2093 * 2, len(combo) / FS) * 0.2 * (np.sin(np.linspace(0, 40, len(combo))) > 0)
    guardar("combo", combo + brillo, 0.5)

    # burbuja: "blup" con seno ascendente
    t = t_de(0.13)
    f = barrido(280, 950, 0.13, 0.6) * (1 + 0.1 * np.sin(2 * np.pi * 40 * t))
    guardar("burbuja", onda("seno", f, 0.13) * envolvente(len(t), 0.003, 0.05, 0.6, 0.05), 0.5)

    # golpe a la mancha: chapoteo
    t = t_de(0.15)
    s = onda("ruido", 0, 0.15) * decaer(len(t), 10) * 0.6 + onda("seno", barrido(220, 70, 0.15), 0.15) * decaer(len(t), 6)
    guardar("golpe", s, 0.55)

    # daño al jugador
    t = t_de(0.25)
    s = onda("cuadrada", barrido(520, 90, 0.25), 0.25, 0.5) * decaer(len(t), 5) + onda("ruido", 0, 0.25) * decaer(len(t), 14) * 0.4
    guardar("dano", s, 0.5)

    # imán activado: barrido con trémolo
    t = t_de(0.55)
    f = barrido(300, 1000, 0.55) * (1 + 0.06 * np.sin(2 * np.pi * 14 * t))
    guardar("iman", onda("triangular", f, 0.55) * envolvente(len(t), 0.01, 0.1, 0.8, 0.15), 0.5)

    # mancha derrotada: estallido
    t = t_de(0.35)
    s = onda("ruido", 0, 0.35) * decaer(len(t), 9) * 0.7
    s += onda("cuadrada", barrido(700, 200, 0.35), 0.35, 0.3) * decaer(len(t), 5) * 0.5
    s += concatenar(np.zeros(int(FS * 0.15)), tono("G6", 0.2, "seno", rapidez=5) * 0.6)
    guardar("mancha_derrotada", s, 0.5)

    # residuo flotante se escapa
    guardar("escapa", concatenar(tono("E5", 0.12, "triangular", rapidez=3), tono("C5", 0.25, "triangular", rapidez=3)), 0.5)

    # mochila llena
    guardar("lleno", concatenar(tono("A3", 0.07, "cuadrada", 0.3, 3), np.zeros(int(FS * 0.03)), tono("A3", 0.09, "cuadrada", 0.3, 3)), 0.35)

    # botón de menú
    guardar("boton", tono("A5", 0.05, "cuadrada", 0.25, 5), 0.35)

    # victoria: fanfarria
    v = concatenar(tono("G5", 0.12), tono("C6", 0.12), tono("E6", 0.12), tono("G6", 0.12),
                   np.zeros(int(FS * 0.05)), tono("E6", 0.1), tono("G6", 0.6, rapidez=2.5))
    armonia = concatenar(np.zeros(int(FS * 0.53)), tono("C6", 0.7, "triangular", rapidez=2.5) * 0.6)
    armonia = np.pad(armonia, (0, max(0, len(v) - len(armonia))))[:len(v)]
    guardar("victoria", v + armonia, 0.5)

    # derrota: descenso triste
    guardar("derrota", concatenar(tono("E5", 0.25, "triangular", rapidez=2), tono("D#5", 0.25, "triangular", rapidez=2),
                                  tono("D5", 0.25, "triangular", rapidez=2), tono("C#5", 0.8, "triangular", rapidez=1.5)), 0.5)


# ------------------------------------------------------------ música
# "Bambuco del río" - composición original en Sol mayor, compás 3/4.
# Cada compás tiene 6 corcheas. Formato: "NOTA:duración_en_corcheas", R = silencio.
TEMPO = 132  # negras por minuto
CORCHEA = 60.0 / TEMPO / 2.0

MELODIA_A = [
    "B4:2 D5:2 G5:1 F#5:1", "E5:2 D5:2 B4:2", "C5:2 E5:2 G5:1 E5:1", "F#5:3 E5:1 D5:2",
    "E5:2 G5:2 B5:1 A5:1", "G5:2 E5:2 C5:2", "D5:2 F#5:1 A5:1 G5:1 F#5:1", "G5:4 R:2",
]
MELODIA_B = [
    "E5:1 F#5:1 G5:2 E5:2", "F#5:1 G5:1 A5:2 F#5:2", "D5:2 F#5:2 B5:2", "B5:1 A5:1 G5:2 E5:2",
    "C5:2 E5:1 G5:1 C6:2", "B5:1 A5:1 F#5:2 D5:2", "G5:2 B4:1 D5:1 G5:2", "G5:3 R:3",
]
ACORDES_A = ["G", "G", "C", "D", "Em", "C", "D", "G"]
ACORDES_B = ["C", "D", "Bm", "Em", "C", "D", "G", "G"]
ACORDES = {
    "G": ["G2", "D3", "B3", "D4", "G4"],
    "C": ["C3", "G3", "E4", "G4", "C5"],
    "D": ["D3", "A3", "F#4", "A4", "D5"],
    "Em": ["E2", "B2", "G4", "B4", "E5"],
    "Bm": ["B2", "F#3", "D4", "F#4", "B4"],
}


def pista_melodia(compases):
    partes = []
    for compas in compases:
        for evento in compas.split():
            nota, dur = evento.split(":")
            d = int(dur) * CORCHEA
            if nota == "R":
                partes.append(np.zeros(int(FS * d)))
            else:
                s = onda("cuadrada", nota_hz(nota), d, 0.25)
                # vibrato suave en notas largas
                if int(dur) >= 3:
                    t = t_de(d)
                    s = onda("cuadrada", nota_hz(nota) * (1 + 0.006 * np.sin(2 * np.pi * 6 * t)), d, 0.25)
                partes.append(s * envolvente(len(s), 0.005, 0.08, 0.55, 0.04))
    return np.concatenate(partes)


def pista_acompanamiento(acordes):
    partes_bajo, partes_arpegio = [], []
    for nombre in acordes:
        notas = ACORDES[nombre]
        # bajo de bambuco: raíz en el tiempo 1, quinta en 2 y 3 (negra con puntillo + corchea)
        for (n, dur) in [(notas[0], 3), (notas[1], 1), (notas[1], 2)]:
            d = dur * CORCHEA
            s = onda("triangular", nota_hz(n), d)
            partes_bajo.append(s * envolvente(len(s), 0.005, 0.1, 0.7, 0.05))
        # arpegio suave en corcheas
        for i in range(6):
            n = notas[2 + (i % 3)]
            s = onda("cuadrada", nota_hz(n), CORCHEA, 0.125)
            partes_arpegio.append(s * decaer(len(s), 7) * 0.5)
    return np.concatenate(partes_bajo), np.concatenate(partes_arpegio)


def pista_percusion(n_compases):
    partes = []
    for _ in range(n_compases):
        for i in range(6):
            s = np.zeros(int(FS * CORCHEA))
            if i == 0:
                k = onda("seno", barrido(140, 40, 0.09), 0.09) * decaer(int(FS * 0.09), 5)
                s[:len(k)] += k
            ruido = onda("ruido", 0, 0.03) * decaer(int(FS * 0.03), 8) * (0.35 if i % 2 == 0 else 0.18)
            s[:len(ruido)] += ruido
            # "chucuchucu" de guacharaca en los tiempos 2 y 3
            if i in (3, 5):
                g = onda("ruido", 0, 0.05) * decaer(int(FS * 0.05), 4) * 0.25
                s[:len(g)] += g
            partes.append(s)
    return np.concatenate(partes)


def musica():
    estructura_mel = MELODIA_A + MELODIA_A + MELODIA_B + MELODIA_A
    estructura_ac = ACORDES_A + ACORDES_A + ACORDES_B + ACORDES_A
    mel = pista_melodia(estructura_mel)
    bajo, arp = pista_acompanamiento(estructura_ac)
    perc = pista_percusion(len(estructura_ac))
    n = min(len(mel), len(bajo), len(arp), len(perc))
    mezcla = mel[:n] * 0.32 + bajo[:n] * 0.42 + arp[:n] * 0.12 + perc[:n] * 0.22
    # sin fundido de salida largo: la pista se repite en bucle
    pico = np.max(np.abs(mezcla))
    datos = (mezcla / pico * 0.55 * 32767).astype(np.int16)
    with wave.open(os.path.join(SALIDA, "musica.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())
    return n / FS


if __name__ == "__main__":
    efectos()
    d = musica()
    print(f"Audio generado en {SALIDA} (música: {d:.1f} s)")
