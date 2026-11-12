shader_type spatial;

uniform vec3 tint_color : source_color = vec3(0.1, 0.7, 0.9);

void vertex() {
	VERTEX.y += sin(TIME + VERTEX.x) * 0.1;
}

void fragment() {
	vec3 rainbow = 0.5 + 0.5 * sin(TIME + UV.xyx * 6.0 + vec3(0.0, 2.0, 4.0));
	
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = smoothstep(0.0, 1.0, rim);
	
	ALBEDO = rainbow;
	EMISSION = tint_color * rim * 1.0;
}