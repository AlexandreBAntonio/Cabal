shader_type sky;
// Céu noturno procedural: gradiente, estrelas cintilando, lua com halo.

uniform vec3 top_color : source_color = vec3(0.015, 0.02, 0.06);
uniform vec3 horizon_color : source_color = vec3(0.16, 0.10, 0.22);
uniform vec3 moon_color : source_color = vec3(0.95, 0.97, 1.0);
uniform vec3 moon_dir = vec3(0.35, 0.45, -0.8);
uniform float star_density = 200.0;

float hash13(vec3 p) {
	p = fract(p * 443.897);
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(h, 0.55));

	// estrelas: células direcionais com brilho pulsante
	if (d.y > 0.02) {
		vec3 cell = floor(d * star_density);
		float star = step(0.997, hash13(cell));
		float tw = 0.55 + 0.45 * sin(TIME * 2.2 + hash13(cell + 7.0) * 12.0);
		col += vec3(0.9, 0.93, 1.0) * star * tw * smoothstep(0.02, 0.2, d.y);
	}

	// lua + halo
	float m = dot(d, normalize(moon_dir));
	col += moon_color * smoothstep(0.9992, 0.9997, m) * 2.5;
	col += vec3(0.35, 0.45, 0.75) * pow(max(m, 0.0), 180.0) * 0.4;

	COLOR = col;
}
