shader_type spatial;

varying vec3 world_position;

void vertex() {
	// Transform local vertex position into world space coordinates
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Map world X, Y, Z coordinates directly to RGB color channels
	ALBEDO = world_position;
}