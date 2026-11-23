// Shader del agua de "Río Limpio".
// Recolorea las baldosas de agua según el nivel de contaminación:
//   contaminacion = 0.0 -> agua azul, limpia y con destellos
//   contaminacion = 1.0 -> agua marrón-grisácea con manchas de aceite
// El juego cambia el parámetro "contaminacion" desde mapa.gd.
shader_type canvas_item;

uniform float contaminacion : hint_range(0.0, 1.0) = 0.25;
uniform vec4 color_limpio : source_color = vec4(0.22, 0.58, 0.86, 1.0);
uniform vec4 color_medio : source_color = vec4(0.30, 0.52, 0.42, 1.0);
uniform vec4 color_sucio : source_color = vec4(0.40, 0.33, 0.22, 1.0);
uniform float velocidad_corriente = 6.0; // píxeles por segundo
uniform vec2 direccion_corriente = vec2(1.0, 0.0); // (1,0) derecha (nivel 1), (0,1) abajo (nivel 2)

// Posición en el mundo (para que las ondas sean continuas entre baldosas)
varying vec2 posicion_mundo;

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// Ruido pseudoaleatorio simple
float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 textura = texture(TEXTURE, UV);
	// Se redondea la posición para conservar el estilo pixel art
	vec2 p = floor(posicion_mundo);
	vec2 corriente = p - floor(TIME * velocidad_corriente) * direccion_corriente;
	// Las ondas se dibujan "acostadas": en un río vertical se giran 90 grados
	if (abs(direccion_corriente.y) > abs(direccion_corriente.x)) {
		corriente = vec2(corriente.y, corriente.x);
	}

	// Brillo propio de la baldosa (sus olas dibujadas)
	float brillo = dot(textura.rgb, vec3(0.299, 0.587, 0.114));

	// Color base: limpio -> medio -> sucio
	vec3 base = mix(color_limpio.rgb, color_medio.rgb, smoothstep(0.0, 0.55, contaminacion));
	base = mix(base, color_sucio.rgb, smoothstep(0.45, 1.0, contaminacion));
	vec3 color = base * (0.55 + brillo * 0.9);

	// Ondas que avanzan con la corriente
	float onda = sin(corriente.x * 0.45 + sin(corriente.y * 0.7) * 2.0) * sin(corriente.y * 0.9 + TIME * 1.5);
	color += step(0.93, onda) * mix(0.22, 0.05, contaminacion);

	// Destellos que sólo aparecen cuando el agua está limpia
	float destello = step(0.997, azar(floor(p / 2.0) + floor(TIME * 2.0)));
	color += destello * (1.0 - contaminacion) * 0.5;

	// Manchas de aceite iridiscentes cuando la contaminación es alta
	// (manchas grandes y alargadas que viajan con la corriente)
	vec2 celda_aceite = floor(corriente / vec2(16.0, 8.0));
	float zona_aceite = step(0.8, azar(celda_aceite)) * step(0.35, azar(celda_aceite + 7.0));
	vec3 arcoiris = 0.5 + 0.5 * cos(TIME * 0.8 + (p.x + p.y) * 0.12 + vec3(0.0, 2.0, 4.0));
	color = mix(color, arcoiris * 0.4 + base * 0.3, zona_aceite * smoothstep(0.55, 1.0, contaminacion) * 0.4);

	COLOR = vec4(color, textura.a);
}
