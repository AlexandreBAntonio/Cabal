shader_type spatial;
// Chão da arena: grid fino + linhas mestras com leve emissão (pega o glow),
// vinheta radial pra focar o centro. Sem texturas externas.

uniform vec3 base_color : source_color = vec3(0.09, 0.095, 0.125);
uniform vec3 line_color : source_color = vec3(0.22, 0.27, 0.36);
uniform vec3 major_color : source_color = vec3(0.25, 0.55, 0.85);
uniform float cells = 60.0;

float grid(vec2 uv, float width) {
	vec2 g = abs(fract(uv - 0.5) - 0.5) / (fwidth(uv) * width);
	return 1.0 - min(min(g.x, g.y), 1.0);
}

void fragment() {
	vec2 uv = UV * cells;
	float minor = grid(uv, 1.0);
	float major = grid(uv / 5.0, 1.3);
	float vign = smoothstep(1.0, 0.15, length(UV - 0.5) * 2.0);

	vec3 col = base_color * (0.55 + 0.45 * vign);
	col = mix(col, line_color, minor * 0.45);
	col = mix(col, major_color, major * 0.7);

	ALBEDO = col;
	EMISSION = major_color * major * 0.35 * vign;
	METALLIC = 0.12;
	ROUGHNESS = 0.45;
}
