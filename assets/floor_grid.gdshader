shader_type spatial;
// Grid procedural pro chão de teste — sem texturas externas.

uniform vec3 base_color : source_color = vec3(0.13, 0.14, 0.17);
uniform vec3 line_color : source_color = vec3(0.32, 0.36, 0.42);
uniform float cells = 60.0;

void fragment() {
	vec2 uv = UV * cells;
	vec2 g = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float line = 1.0 - min(min(g.x, g.y), 1.0);
	ALBEDO = mix(base_color, line_color, line);
	ROUGHNESS = 0.9;
}
