shader_type spatial;
// Piso de pedra da arena: placas voronoi com frestas escuras + manchas de
// noise. Tudo procedural, sem texturas externas.

uniform vec3 stone_a : source_color = vec3(0.17, 0.165, 0.185);
uniform vec3 stone_b : source_color = vec3(0.115, 0.11, 0.13);
uniform vec3 crack_color : source_color = vec3(0.045, 0.045, 0.06);
uniform float tiles = 16.0;

vec2 hash22(vec2 p) {
	vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
	a += dot(a, a + 34.45);
	return fract(vec2(a.x * a.y, a.y * a.z));
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 443.897);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV * tiles;
	vec2 i = floor(uv);
	vec2 f = fract(uv);

	// voronoi F2-F1: frestas nas bordas das placas
	float f1 = 8.0;
	float f2 = 8.0;
	float cell_id = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash22(i + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				cell_id = hash12(i + g);
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	float edge = f2 - f1;
	float crack = 1.0 - smoothstep(0.0, 0.07, edge);

	float n = vnoise(uv * 3.0) * 0.6 + vnoise(uv * 9.0) * 0.4;
	vec3 slab = mix(stone_a, stone_b, n);
	slab *= 0.9 + cell_id * 0.2;                 // variação por placa
	vec3 col = mix(slab, crack_color, crack * 0.85);

	// vinheta sutil pra focar o centro da arena
	float vign = smoothstep(1.05, 0.2, length(UV - 0.5) * 2.0);
	col *= 0.65 + 0.35 * vign;

	ALBEDO = col;
	ROUGHNESS = 0.62 + crack * 0.25 - n * 0.12;
	METALLIC = 0.05;
	NORMAL_MAP = vec3(0.5, 0.5, 1.0);
}
