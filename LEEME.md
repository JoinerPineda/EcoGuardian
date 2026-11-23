# EcoGuardián · Limpia los ríos de Caldas

Videojuego 2D *top-down* hecho en **Godot 4.4 con GDScript**, sin plugins. Proyecto de la
clase de Programación para Videojuegos.

Eres un EcoGuardián (con sombrero aguadeño) que limpia los ríos de Caldas. Recoges la basura del
suelo y la que baja flotando por el río y la llevas a las canecas según el **código de colores
de Colombia (Resolución 2184 de 2019)**. Si dejas que el río se contamine, pierdes.

El juego tiene **2 niveles**:

| | Nivel 1 · La finca cafetera | Nivel 2 · El pueblo |
|---|---|---|
| Paisaje | Finca con cafetal, guadua, estanque y río que corre hacia la derecha | Pueblo colonial con calles de adoquín, plaza con fuente, casas de bahareque, guayacanes, faroles y malecón de ladrillo; el río baja de arriba hacia abajo |
| Meta | Reciclar **12** residuos | Reciclar **15** residuos |
| Enemigos | Manchas de petróleo (máx. 2) | Manchas de petróleo más rápidas (máx. 3) y **bolsas voladoras** (máx. 2) |
| Contaminación | Empieza en 20 % y sube despacio | Empieza en 30 % y sube más rápido; la basura del río baja más rápido |
| Música | Bambuco (Sol mayor, 3/4) | Cumbia (La menor, 4/4) |
| Extra | Tutorial guiado al inicio | Se desbloquea al ganar el nivel 1 |

---

## 1. Cómo abrir el proyecto

1. Instala **Godot 4.4** o superior (versión estándar, no hace falta la de .NET).
2. En el Administrador de proyectos pulsa **Importar** y elige el archivo `project.godot`
   de la carpeta del proyecto (o el ZIP descargado de GitHub).
3. La primera vez Godot importa las imágenes y los sonidos (unos segundos).
4. Pulsa **F5** (Ejecutar proyecto). Arranca en el menú principal.

Para probar sólo la partida, abre `Escenas/Juego.tscn` y pulsa **F6** (Ejecutar escena actual).

---

## 2. Controles

| Acción | Teclas |
|---|---|
| Moverse (4 direcciones) | **WASD** o **flechas** |
| Depositar en la caneca cercana | **E** |
| Cambiar el residuo seleccionado | **Q**, **Tab** o **1 / 2 / 3** |
| Disparar burbujas de jabón | **Espacio** (hacia donde miras) o **clic izquierdo** (hacia el puntero) |
| Pausa / continuar | **Esc** o **P** |
| Reiniciar (en pausa o al final) | **R** |
| Siguiente nivel / botón elegido (pantalla final) | **Enter** |
| Volver al menú (pantalla final) | **Esc** |
| Silenciar / activar el sonido | **M** o el botón del altavoz (portada y pausa) |
| Saltar el tutorial | **Enter** |

Con dos teclas de dirección a la vez manda **la última que presionaste**, como en el Zelda
original. Todas las acciones están en *Proyecto > Configuración del proyecto > Mapa de entrada*.

---

## 3. Reglas

- **Residuos:** aparecen solos en el suelo y también bajan flotando por el río.
  Se recogen al tocarlos. La basura del río se alcanza desde la orilla o desde el puente.
- **Mochila:** guarda máximo **3** residuos. El seleccionado aparece resaltado abajo a la izquierda.
- **Canecas** (en la plaza): acércate y pulsa **E** para depositar el residuo seleccionado.
  - Acierto: **+10 puntos** y la contaminación baja 5 %.
  - Error: **−5 puntos** y la contaminación sube 5 %. El juego te dice cuál era la caneca correcta.
  - **Combo:** cada 3 aciertos seguidos dan **+15 puntos extra**. Un error reinicia la racha.
- **Contaminación:** sube sola mientras haya basura sin recoger (en el suelo o en el río).
  Si un residuo flotante se escapa río abajo, sube 4 % (5 % en el nivel 2). Al derrotar un enemigo baja 2 %.
  **Si llega a 100 %, pierdes.** El agua (shader) y todo el paisaje cambian de color según su valor.
- **Manchas de petróleo:** aparecen lejos de ti, te persiguen, te quitan un corazón y te frenan
  mientras te tocan. Se derrotan con **2 burbujas**. A veces sueltan un **imán**: durante
  **10 segundos** atrae la basura del suelo **y la del río** que esté a menos de 140 px (casi
  media pantalla). Si la mochila está llena el imán no puede atraer nada, y el juego lo avisa.
- **Bolsas voladoras (nivel 2):** el viento las lleva por todo el mapa, incluso sobre el río. Si
  te ven te siguen y cada vez que te tocan la **contaminación sube 5 %**. Además, si llevas algo,
  **te quitan el residuo seleccionado** (cae al suelo cerca); si tu mochila está vacía, te quitan
  **un corazón**. Después de cada golpe se alejan volando un momento. Se atrapan con **2 burbujas** y caen
  como una **bolsa plástica** que hay que llevar a la caneca **blanca**.
- Al derrotar enemigos aparecen **datos educativos** (por qué el aceite y las bolsas dañan el río).
- Tienes 3 corazones: si los pierdes todos, pierdes.
- **Victoria:** reciclar bien **12 residuos** en el nivel 1 y **15** en el nivel 2.
- **Calificación:**
  - ★ ganar.
  - ★★ ganar con la contaminación final por debajo del 50 %.
  - ★★★ además, clasificar con una precisión de al menos 85 %.
- **Música:** el menú, la trivia y el nivel 1 usan un bambuco; el nivel 2 tiene su propia cumbia
  (cada nivel define su pista en `niveles.gd`, clave `"musica"`).
- **Récord y progreso:** el mejor puntaje, las estrellas, el nivel desbloqueado, si ya se vio el
  tutorial y el sonido silenciado se guardan en disco (`user://ecoguardian.cfg`; en Windows está
  en `%APPDATA%\Godot\app_userdata\EcoGuardián\`).
- Dentro de cada nivel la dificultad sube con el progreso: más residuos a la vez, basura más
  rápida y más enemigos.

### Portada

Hay 5 estilos de portada. Se elige en el nodo raíz de `Escenas/MenuPrincipal.tscn`, propiedad
**Estilo Portada** (1 a 5): 1 Amanecer en el Nevado, 2 Atardecer cafetero, 3 Noche de
luciérnagas, 4 Valle de Cocora, 5 El pueblo. Cada estilo cambia el fondo, los colores del
título, el tono del paisaje y del río (la lista `PORTADAS` de `menu_principal.gd`).

### Tutorial

Al empezar el nivel 1 aparece un tutorial de 4 pasos (moverse, recoger, depositar en la caneca
correcta y disparar) con una flecha que señala el residuo y la caneca. Mientras dura no aparece
basura nueva ni enemigos y la contaminación no sube. Sale la primera vez que se juega en el
computador y para cada estudiante nuevo registrado en la trivia. Se salta con **Enter**.

### Clasificación (Resolución 2184 de 2019)

| Caneca | Qué va | Residuos del juego |
|---|---|---|
| **Blanca** (aprovechables) | plástico, vidrio, metales, papel y cartón, limpios y secos | botella plástica, lata, botella de vidrio, periódico, caja de cartón, bolsa plástica (la deja la bolsa voladora) |
| **Verde** (orgánicos aprovechables) | restos de comida, cáscaras, poda | cáscara de banano, corazón de manzana, pulpa de café, cáscaras de huevo, hojas y poda |
| **Negra** (no aprovechables) | servilletas y papel higiénico usados, metalizados, icopor sucio | servilleta usada, empaque metalizado, icopor sucio, tapabocas |

---

## 4. Estructura de carpetas

```
EcoGuardian/
├── project.godot          Configuración: 320x180, filtro nearest, canvas_items, Input Map, autoloads
├── LEEME.md
├── Assets/                Imágenes (pixel art original) y recursos
│   ├── jugador.png        4 filas (abajo, arriba, izquierda, derecha) x 4 cuadros de 16x16
│   ├── mancha.png         4 cuadros de movimiento + 1 de golpe (16x16)
│   ├── residuos.png       15 residuos de 16x16 en una tira (el 15 es la bolsa plástica)
│   ├── canecas.png        blanca, verde, negra (16x24 cada una)
│   ├── tileset.png        baldosas de 16x16 (finca y pueblo: adoquín, andén, malecón, faroles...)
│   ├── casas_pueblo.png   3 casas coloniales de 48x48 (nivel 2)
│   ├── bolsa.png          bolsa voladora: 4 cuadros de vuelo + 1 de golpe (16x16)
│   ├── portada_1.png ... portada_5.png    5 fondos de portada (ver "Portada")
│   ├── nubes.png, logo.png                nubes animadas y logo de la portada
│   ├── sonido.png         altavoz activo / silenciado (12x12)
│   ├── casa.png, burbuja.png, iman.png, corazones.png, estrellas.png, sombra.png, icono.png
│   ├── tileset.tres       TileSet: colisiones, dato "generable", orden Y de obstáculos altos
│   ├── jugador_frames.tres / mancha_frames.tres   SpriteFrames
│   └── tema.tres          Tema de la interfaz (botones, paneles, fuentes)
├── Audio/                 Efectos .wav y música original (musica.wav, bambuco en 3/4)
├── Escenas/
│   ├── MenuPrincipal.tscn Escena inicial
│   ├── Juego.tscn         La partida: Mapa + Jugador + generadores + HUD + menús
│   ├── Mapa.tscn          Nivel 1: la finca (48x30 celdas, TileMapLayer)
│   ├── Mapa2.tscn         Nivel 2: el pueblo (44x30 celdas, río vertical)
│   ├── Personajes/        Jugador.tscn, Mancha.tscn, Bolsa.tscn
│   ├── Objetos/           Residuo, ResiduoFlotante, Caneca, Casa, CasaPueblo, Burbuja, PowerUpIman, TextoFlotante
│   └── Interfaz/          HUD, MenuPausa, PantallaFinal, Transicion, Trivia, Resultados, Tutorial, BotonSonido
├── Scripts/
│   ├── juego.gd           Reglas: puntos, combo, contaminación, victoria y derrota
│   ├── niveles.gd         Datos de cada nivel: mapa, meta, contaminación, generadores y enemigos
│   ├── jugador.gd, mancha.gd, bolsa.gd, residuo.gd, residuo_flotante.gd, caneca.gd, burbuja.gd,
│   │   power_up_iman.gd, texto_flotante.gd, mapa.gd, casa_pueblo.gd
│   ├── tutorial.gd, boton_sonido.gd
│   ├── generador_residuos.gd, generador_flotantes.gd, generador_enemigos.gd
│   ├── hud.gd, menu_principal.gd, menu_pausa.gd, pantalla_final.gd
│   ├── reciclaje.gd       Catálogo de residuos, canecas, datos educativos y estrellas
│   ├── trivia.gd, resultados.gd   Evaluación del aprendizaje (ver sección 11)
│   ├── Globales/          Autoloads: sonido.gd, guardado.gd, transicion.gd, evaluacion.gd
│   └── Herramientas/      constructor_mapa.gd y los generadores en Python del arte y el audio
└── Shaders/
    ├── agua.gdshader      Color del agua según la contaminación; dirección de la corriente
    ├── agua_material.tres     Nivel 1 (azul, corre a la derecha)
    └── agua_material_2.tres   Nivel 2 (verdoso, corre hacia abajo)
```

### Capas de colisión (Proyecto > Configuración > Nombres de capas > Física 2D)

| Capa | Nombre | Quién está en ella |
|---|---|---|
| 1 | mundo | obstáculos del TileSet, casa, canecas |
| 2 | jugador | Jugador |
| 3 | enemigos | Mancha |
| 4 | recogibles | residuos, residuos flotantes, imán |
| 5 | burbujas | burbujas de jabón |
| 6 | agua | baldosas de agua (bloquean al jugador y a las manchas, **no** a las burbujas) |

---

## 5. Conceptos de clase y dónde están

| Concepto | Dónde verlo |
|---|---|
| `CharacterBody2D` + `move_and_slide()` | `jugador.gd`, `mancha.gd` |
| `AnimatedSprite2D` / `SpriteFrames` | `Jugador.tscn` (animaciones `quieto_*` y `caminar_*` por dirección), `Mancha.tscn` |
| `Area2D` con señales | `residuo.gd` (`body_entered`), `caneca.gd` (zona de depósito), `burbuja.gd`, `power_up_iman.gd`, zona de contacto de `mancha.gd` |
| Señales propias | `Jugador.mochila_cambiada`, `vida_cambiada`, `murio`...; `Caneca.residuo_depositado`; `Mancha.derrotada`; `ResiduoFlotante.escapo`; `juego.gd` → HUD |
| Grupos | `"jugador"`, `"residuos"`, `"flotantes"`, `"enemigos"`, `"canecas"`, `"power_ups"` |
| Instanciar escenas (`PackedScene`) | los tres generadores, `jugador.gd` (burbujas), `mancha.gd` (imán), `juego.gd` (textos flotantes) |
| `Timer` | generadores, imán, disparo e invulnerabilidad del jugador, rumbo de la mancha |
| `Tween` | aparición de residuos, rebote de canecas, parpadeo por daño, sacudida de cámara, barra del HUD, combo, estrellas, transición entre escenas |
| `TileMapLayer` + `TileSet` + colisiones | `Mapa.tscn` (capas Suelo, Agua, Puente, Obstaculos) y `Assets/tileset.tres` |
| Datos personalizados del TileSet | dato `generable` en `mapa.gd` (decide dónde aparece la basura) |
| `Camera2D` con límites | `Jugador.tscn`; los límites se calculan con el mapa en `juego.gd` |
| Orden por profundidad (`y_sort`) | raíz de `Mapa.tscn`, `Obstaculos` (con `y_sort_origin` por baldosa), `Objetos`, `Canecas` |
| Input Map | `project.godot` (sección `[input]`) |
| `@export`, `@onready`, `class_name` | en todos los scripts (por ejemplo `Jugador`, `Caneca`, `Mapa`, `Reciclaje`) |
| `Path2D` / `PathFollow2D` (extra) | `RutaRio` en el mapa; cada `ResiduoFlotante` sigue el río |
| Shader | `Shaders/agua.gdshader` (parámetro `contaminacion`) + `CanvasModulate` en `Juego.tscn` |
| Autoloads (singletons) | `Sonido`, `Guardado`, `Transicion`, `Evaluacion` |
| Guardar en disco | `guardado.gd` con `ConfigFile`; `evaluacion.gd` con `JSON` y exportación `CSV` en `user://` |

---

## 6. Cómo probar cada fase en Godot

**Fase 1: movimiento y mapa**
1. Abre `Escenas/Mapa.tscn` (nivel 1) y `Escenas/Mapa2.tscn` (nivel 2, el pueblo).
2. Abre `Escenas/Juego.tscn` y pulsa **F6**. Camina con WASD o las flechas.
3. Comprueba que:
   - el agua, los árboles, las rocas y los bordes no te dejan pasar;
   - puedes cruzar por el puente;
   - pasas *detrás* de los árboles al subir y *delante* al bajar (y_sort);
   - la cámara no se sale del mapa.

**Fase 2: residuos y canecas**
1. Toca residuos: aparecen en las ranuras 1-2-3. Con la mochila llena sale un aviso.
2. Ve a la plaza y pulsa **E** junto a una caneca. Prueba acertar (+10), fallar (−5) y hacer 3 aciertos seguidos (combo).
3. Párate en el puente o en la orilla cuando pase basura flotando.
4. Para probar la victoria rápido: baja el valor `"meta"` del nivel en `Scripts/niveles.gd` (por ejemplo a 2).
5. Para jugar directo el nivel 2 con F6: en `Scripts/Globales/guardado.gd` cambia `var nivel_actual := 1` por `2`
   (recuerda devolverlo a 1).

**Fase 3: enemigos**
1. A los ~12 s aparece una mancha. Déjate tocar (pierdes un corazón y te frena) y luego dispárale 2 burbujas con Espacio o clic.
2. Para ver siempre el imán: abre `Escenas/Personajes/Mancha.tscn` y pon **Probabilidad Iman** en 1.

**Fase 4: interfaz**
1. Ejecuta con **F5**: menú → Jugar → **Esc** (pausa) → R (reinicia) → Menú principal.
2. Gana o pierde para ver la pantalla final con estrellas, estadísticas, dato educativo y récord.
3. Vuelve al menú: el récord aparece arriba a la izquierda.

**Fase 5: pulido**
1. En el Inspector de **Juego**, pon **Contaminacion Inicial** en 90. El agua se ve marrón con manchas de aceite y el paisaje se pone gris.
2. Escucha los sonidos de recoger, acertar, fallar, combo, burbujas, golpe, daño, imán, victoria y derrota, y la música en bucle.

---

## 7. Arte y audio (todo original)

Todo el arte y el audio fueron **generados por código** para este proyecto, así que no tienen
derechos de terceros. Los scripts están en `Scripts/Herramientas/Python/`
(esa carpeta tiene un archivo `.gdignore` para que Godot la ignore):

```
python3 generar_arte.py         ../../../Assets   # requiere Pillow
python3 generar_arte_nivel2.py  ../../../Assets   # arte de la versión 2 (después del anterior)
python3 generar_portadas.py     ../../../Assets   # los 5 fondos de portada
python3 generar_audio.py        ../../../Audio    # requiere numpy
python3 generar_audio_nivel2.py ../../../Audio    # cumbia del nivel 2
```

**Reemplazar por arte propio:** todos los PNG son reemplazables. Si conservas el **mismo nombre,
tamaño y distribución de cuadros**, no hay que tocar el código:

| Archivo | Tamaño | Distribución |
|---|---|---|
| `jugador.png` | 64x64 | filas abajo, arriba, izquierda, derecha; 4 cuadros de 16x16 |
| `mancha.png` | 80x16 | 4 cuadros de movimiento + 1 cuadro de golpe |
| `residuos.png` | 240x16 | 15 cuadros: los 14 de `Reciclaje.RESIDUOS` + la bolsa plástica |
| `canecas.png` | 48x24 | blanca, verde, negra |
| `tileset.png` | 128x80 | celdas de 16x16 |
| `bolsa.png` | 80x16 | 4 cuadros de vuelo + 1 cuadro de golpe |
| `casas_pueblo.png` | 144x48 | 3 casas de 48x48 |

Los que más conviene mejorar si quieren un acabado de entrega final son `jugador.png`,
`mancha.png` y `tileset.png`. Los sonidos se reemplazan con otro `.wav` u `.ogg` del mismo
nombre (si cambias la extensión, actualiza `Scripts/Globales/sonido.gd`).

---

## 8. Cambiar el mapa

- **Opción A (editor):** abre `Escenas/Mapa.tscn` o `Escenas/Mapa2.tscn`, selecciona una capa (`Suelo`, `Agua`,
  `Puente` u `Obstaculos`) y pinta con el panel **TileMap**. El agua va en la capa `Agua`.
- **Opción B (texto):** edita la constante `MAPA` (nivel 1) o `MAPA_2` (nivel 2) de `Scripts/Herramientas/constructor_mapa.gd`
  (cada carácter es una celda; la leyenda está en el mismo archivo) y ejecuta en una terminal,
  dentro de la carpeta del proyecto:
  ```
  godot --headless --script res://Scripts/Herramientas/constructor_mapa.gd
  ```
  Esto regenera `Mapa.tscn`, `Mapa2.tscn`, el TileSet, los materiales del agua, la ruta del río y
  los SpriteFrames. Sobrescribe los cambios hechos a mano en los mapas.

---

## 9. Ajustar la dificultad

La dificultad de cada nivel está en **`Scripts/niveles.gd`**, en una sola lista fácil de leer:
meta, contaminación inicial, qué tan rápido sube, ritmo de la basura del suelo y del río,
cuándo aparecen los enemigos y cuántos de cada tipo. Juego.gd aplica esos valores al empezar,
así que tienen prioridad sobre los del Inspector de los generadores.

Lo demás es `@export` y se cambia desde el Inspector:

- **Juego** (nodo raíz de `Juego.tscn`): puntos y combo.
- **Jugador**: velocidad, vida, radio del imán y cadencia de disparo.
- **Mancha**: velocidades, radio de detección, vida y probabilidad del imán.
- **Bolsa** (`Escenas/Personajes/Bolsa.tscn`): velocidades de vuelo, persecución y huida, radio y vida.

Para agregar un nivel 3: crea su mapa (copia `MAPA_2` en el constructor y agrégalo a `MAPAS`) y
añade un diccionario más a la lista de `niveles.gd`. El menú y la pantalla final lo detectan solos.

---

## 10. Decisiones de diseño respecto al documento del proyecto

- El documento proponía 4 canecas (orgánico, plástico, vidrio/metal, papel). Se usan las **3
  canecas de la norma colombiana vigente** (blanca, verde y negra), como se pidió.
- Las manchas de petróleo **persiguen, hacen daño y además frenan** al jugador (el documento
  decía que "frenan al jugador").
- Se implementaron **2 niveles** (finca y pueblo) con paisajes, ríos y enemigos distintos, en
  lugar de los 4 sugeridos; el sistema de `niveles.gd` permite agregar más. El efecto de "agua
  que se aclara" sí está incluido (shader + `CanvasModulate`).
- El **dato educativo** al terminar cada partida y el **puntaje guardado** salen del documento.
- El power-up es el **imán** (el documento lo deja "para más adelante"). La red y las botas
  quedan como posibles extensiones.
- El segundo enemigo es la **bolsa voladora**: en lugar de solo hacer daño, **quita residuos**,
  lo que obliga a decidir cuándo ir a las canecas. Además enseña que las bolsas plásticas
  llegan a los ríos con el viento.

---

## 12. Versión web (GitHub y Vercel)

La versión para navegador ya está exportada en `build/web/` (la carpeta tiene un `.gdignore`
para que Godot no la importe). Vercel publica esa carpeta tal cual, según `vercel.json`.

Para volver a exportarla después de cambiar el juego:

1. En Godot: **Editor → Administrar plantillas de exportación → Descargar e instalar**
   (una sola vez, pesa cerca de 1 GB).
2. **Proyecto → Exportar…**, elige el preset **Web** (ya está en `export_presets.cfg`, con
   "Thread Support" apagado para que funcione en cualquier hosting) y pulsa
   **Exportar proyecto** sobre `build/web/index.html`.
3. Sube los cambios a GitHub (`git add .`, `git commit`, `git push`): Vercel publica solo
   la nueva versión en uno o dos minutos.

En la versión web:
- El botón **Salir** no aparece (el navegador no deja cerrar la pestaña desde el juego).
- El récord y las evaluaciones se guardan **en ese navegador**. En el panel de Resultados el
  botón **Descargar CSV** baja `evaluaciones.csv` a la carpeta de Descargas.
- Para las pruebas con estudiantes en un mismo computador sirven las dos versiones; si cada
  estudiante usa un computador distinto, cada uno tendrá sus propios datos.

---

## 11. Evaluación del aprendizaje (trivia inicial y final)

Para medir si el juego cumple su propósito pedagógico, cada participante responde una **trivia
de 5 preguntas antes de jugar y otra de 5 preguntas distintas después**, sobre los mismos
5 temas, y una encuesta corta de experiencia.

**Flujo de un estudiante**

1. En el menú pulsa **Jugar**. Si no hay un participante en curso, escribe su nombre, ve una
   **explicación de las 3 canecas** (qué recibe cada una, con el dibujo de cada residuo) y
   hace la **trivia inicial** (pre-test). Aquí el juego **no** dice si acertó, para medir lo
   que sabía antes de jugar.
2. Juega una o más partidas. Cada partida queda registrada (puntaje, precisión, estrellas).
3. Al terminar una partida aparece el botón **Trivia final** (también está en el menú, junto
   al nombre del participante). Responde **5 preguntas nuevas** de los mismos temas, ahora
   **con retroalimentación** (correcto / incorrecto + explicación).
4. Responde la **encuesta de experiencia** (diversión, facilidad, aprendizaje y si lo
   recomendaría, de 1 a 5).
5. Ve su comparación **antes vs. después** y qué temas debe repasar.

Si otro estudiante va a jugar en el mismo computador, se pulsa **Cambiar** en el menú.

**Preguntas** (`Scripts/Globales/evaluacion.gd`). La pregunta N de cada trivia mide el mismo
tema, así se puede comparar tema por tema:

| Tema | Trivia inicial (`PREGUNTAS_INICIAL`) | Trivia final (`PREGUNTAS_FINAL`) |
|---|---|---|
| Caneca blanca | Botella plástica | Lata de gaseosa |
| Caneca verde | Cáscara de banano | Pulpa de café |
| Caneca negra | Empaque metalizado | Icopor sucio |
| Petróleo en el río | ¿Por qué le hace daño al río? | ¿Qué les pasa a los peces? |
| Bolsas plásticas | ¿Por qué son un peligro? | ¿En qué caneca va una bolsa limpia? |

Para cambiarlas basta editar esas listas; si cambias los bancos, sube `VERSION_DATOS` para que
los resultados viejos se guarden aparte y no se mezclen.

> Nota para el análisis: como la explicación de las canecas sale **antes** de la trivia inicial,
> las preguntas de clasificación miden lo que el estudiante retiene de esa explicación y el
> juego refuerza. Los temas de petróleo y bolsas sólo se enseñan jugando.

**Análisis de resultados (docente)**

- Botón **Resultados** (arriba a la derecha del menú): promedio de aciertos antes y después,
  porcentaje de participantes que mejoraron, gráfica de aciertos **por pregunta** (gris = antes,
  verde = después), temas **a reforzar** (menos de 60 % de aciertos en la trivia final) y
  promedio de la encuesta.
- Todos los datos se exportan a **`user://evaluaciones.csv`** (botón *Abrir carpeta*). Una fila
  por participante con: aciertos inicial y final, mejora, partidas, nivel máximo superado, mejor puntaje, precisión,
  estrellas, tiempos, respuestas de la encuesta y acierto (1/0) de cada pregunta en cada trivia.
  Usa `;` como separador y tildes en UTF-8, así que abre directo en Excel en español o en
  Google Sheets. En Windows la carpeta es `%APPDATA%\Godot\app_userdata\EcoGuardián\`.
- *Borrar datos* (pide confirmación) limpia los registros entre grupos.
- Para probar el juego sin trivia, pon `activa = false` en `evaluacion.gd`.

| Archivo | Qué hace |
|---|---|
| `Scripts/Globales/evaluacion.gd` | Autoload `Evaluacion`: banco de preguntas, encuesta, guardado (JSON + CSV) y análisis |
| `Escenas/Interfaz/Trivia.tscn` + `Scripts/trivia.gd` | Registro, preguntas, retroalimentación, encuesta y comparación |
| `Escenas/Interfaz/Resultados.tscn` + `Scripts/resultados.gd` | Panel de análisis para el docente |
