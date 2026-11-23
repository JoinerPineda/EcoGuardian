#!/usr/bin/env python3
"""
Música del nivel 2 de EcoGuardián: "Cumbia del pueblo" (composición original).
Contrasta con el bambuco del nivel 1 (Sol mayor, 3/4): está en La menor, en
compás de 4/4, con bajo saltarín, acordes a contratiempo, guacharaca en
semicorcheas, tambor y una melodía tipo gaita (flauta con vibrato).
Usa las mismas funciones de síntesis de generar_audio.py (no usa muestras).

Uso:  python3 generar_audio_nivel2.py <carpeta_Audio>     (requiere numpy)
"""
import os, sys, wave
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from generar_audio import FS, onda, barrido, envolvente, decaer, nota_hz, t_de

SALIDA = sys.argv[1] if len(sys.argv) > 1 else "Audio"
os.makedirs(SALIDA, exist_ok=True)
rng = np.random.default_rng(11)

TEMPO = 104                      # negras por minuto
CORCHEA = 60.0 / TEMPO / 2.0     # cada compás tiene 8 corcheas

# Formato: "NOTA:duración_en_corcheas", R = silencio. Cada compás suma 8.
MELODIA_A = [
    "E5:2 A5:2 G5:1 A5:1 C6:2", "B5:2 A5:1 G5:1 D5:4", "C5:1 D5:1 F5:2 A5:2 G5:1 F5:1", "E5:3 D5:1 B4:2 G#4:2",
    "A4:2 C5:2 E5:2 A5:2", "F5:1 E5:1 D5:2 F5:2 A5:2", "G#5:2 B5:2 E5:1 F5:1 G#5:2", "A5:6 R:2",
]
MELODIA_B = [
    "G5:2 E5:1 G5:1 C6:2 B5:1 A5:1", "B5:2 D6:2 B5:2 G5:2", "A5:2 C6:1 A5:1 E5:2 C5:2", "B4:2 E5:2 G5:2 B5:2",
    "A5:2 F5:1 A5:1 C6:2 A5:2", "G5:2 E5:2 C5:2 E5:2", "F5:2 A5:1 F5:1 D5:2 F5:2", "E5:2 G#5:2 B5:2 E5:2",
]
ACORDES_A = ["Am", "G", "F", "E", "Am", "Dm", "E", "Am"]
ACORDES_B = ["C", "G", "Am", "Em", "F", "C", "Dm", "E"]
ACORDES = {   # bajo, quinta, y tres notas del acorde
    "Am": ["A2", "E3", "A3", "C4", "E4"],
    "G": ["G2", "D3", "G3", "B3", "D4"],
    "F": ["F2", "C3", "F3", "A3", "C4"],
    "E": ["E2", "B2", "E3", "G#3", "B3"],
    "Dm": ["D3", "A3", "D4", "F4", "A4"],
    "C": ["C3", "G3", "C4", "E4", "G4"],
    "Em": ["E2", "B2", "E3", "G3", "B3"],
}


def gaita(nota, d):
    """Flauta de caña: triangular + seno, vibrato que entra despacio y un soplo de aire."""
    t = t_de(d)
    vibrato = 1 + 0.009 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.15, 0, 1)
    f = nota_hz(nota) * vibrato
    s = onda("triangular", f, d) * 0.7 + onda("seno", f * 2, d) * 0.18
    aire = onda("ruido", 0, d) * decaer(int(FS * d), 18) * 0.12
    return (s + aire) * envolvente(len(s), 0.02, 0.1, 0.75, 0.05)


def pista_melodia(compases):
    partes = []
    for compas in compases:
        for evento in compas.split():
            nota, dur = evento.split(":")
            d = int(dur) * CORCHEA
            partes.append(np.zeros(int(FS * d)) if nota == "R" else gaita(nota, d))
    return np.concatenate(partes)


def pista_acompanamiento(acordes):
    bajo, contratiempo = [], []
    for nombre in acordes:
        notas = ACORDES[nombre]
        # Bajo de cumbia: raíz - quinta - raíz - quinta, con un respiro antes de la quinta
        for (n, dur) in [(notas[0], 2), (None, 1), (notas[1], 1), (notas[0], 2), (None, 1), (notas[1], 1)]:
            d = dur * CORCHEA
            if n is None:
                bajo.append(np.zeros(int(FS * d)))
            else:
                s = onda("triangular", nota_hz(n), d)
                bajo.append(s * envolvente(len(s), 0.004, 0.08, 0.6, 0.04))
        # Acorde corto a contratiempo (corcheas 2, 4, 6 y 8): el "chas" de la cumbia
        for i in range(8):
            s = np.zeros(int(FS * CORCHEA))
            if i % 2 == 1:
                acorde = sum(onda("cuadrada", nota_hz(n), CORCHEA * 0.5, 0.25) for n in notas[2:]) / 3
                acorde *= decaer(len(acorde), 9)
                s[:len(acorde)] += acorde
            contratiempo.append(s)
    return np.concatenate(bajo), np.concatenate(contratiempo)


def pista_percusion(n_compases):
    partes = []
    semicorchea = CORCHEA / 2
    for _ in range(n_compases):
        for i in range(16):
            s = np.zeros(int(FS * semicorchea))
            # Guacharaca: raspado en cada semicorchea, acento largo en los tiempos ("chu-cu-chu-cu")
            largo = 0.07 if i % 4 == 0 else 0.035
            g = onda("ruido", 0, min(largo, semicorchea)) * decaer(int(FS * min(largo, semicorchea)), 5 if i % 4 == 0 else 9)
            s[:len(g)] += g * (0.3 if i % 2 == 0 else 0.16)
            # Tambor llamador (grave) en los tiempos 1 y 3
            if i in (0, 8):
                k = onda("seno", barrido(120, 50, 0.12), 0.12) * decaer(int(FS * 0.12), 4)
                s[:min(len(k), len(s))] += k[:len(s)] * 0.9
            # Tambor alegre (más agudo) en la "y" del 2 y del 4, con un repique al final
            if i in (6, 14, 15):
                a = onda("seno", barrido(260, 170, 0.07), 0.07) * decaer(int(FS * 0.07), 6)
                s[:min(len(a), len(s))] += a[:len(s)] * (0.5 if i != 15 else 0.35)
            partes.append(s)
    return np.concatenate(partes)


def musica_nivel2():
    estructura_mel = MELODIA_A + MELODIA_A + MELODIA_B + MELODIA_A
    estructura_ac = ACORDES_A + ACORDES_A + ACORDES_B + ACORDES_A
    mel = pista_melodia(estructura_mel)
    bajo, contra = pista_acompanamiento(estructura_ac)
    perc = pista_percusion(len(estructura_ac))
    n = min(len(mel), len(bajo), len(contra), len(perc))
    mezcla = mel[:n] * 0.34 + bajo[:n] * 0.4 + contra[:n] * 0.13 + perc[:n] * 0.26
    pico = np.max(np.abs(mezcla))
    datos = (mezcla / pico * 0.55 * 32767).astype(np.int16)
    with wave.open(os.path.join(SALIDA, "musica_nivel2.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())
    return n / FS


if __name__ == "__main__":
    d = musica_nivel2()
    print(f"musica_nivel2.wav generada en {SALIDA} ({d:.1f} s)")
