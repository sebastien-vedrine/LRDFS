shader_type spatial;
render_mode cull_disabled;
// Gentle wind sway for grass blades (MultiMesh) and foliage blobs (Story 001).
// Vertices are displaced horizontally in world space, scaled by their height
// along the mesh, with a phase derived from the instance's world position.

uniform vec4 albedo : source_color = vec4(0.5, 0.7, 0.4, 1.0);
uniform bool use_instance_color = false;
uniform bool grass_normals = false;
uniform float wind_strength = 0.1;
uniform float wind_speed = 1.2;
uniform vec2 wind_direction = vec2(1.0, 0.35);
uniform float height_offset = 0.0;
uniform float height_range = 1.0;
uniform float height_power = 2.0;
uniform float tip_brighten = 0.25;

varying float v_h;

vec3 srgb_to_linear(vec3 c) {
	vec3 hi = pow((c + vec3(0.055)) / 1.055, vec3(2.4));
	vec3 lo = c / 12.92;
	return mix(hi, lo, step(c, vec3(0.04045)));
}

void vertex() {
	float h = clamp((VERTEX.y + height_offset) / height_range, 0.0, 1.0);
	v_h = h;
	float f = pow(h, height_power);
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec2 dir = normalize(wind_direction);
	float phase = dot(origin.xz, dir) * 0.5 + origin.x * 0.13;
	float t = TIME * wind_speed;
	float s = sin(t + phase) * 0.6 + sin(t * 2.3 + phase * 1.7) * 0.25 + 0.35;
	vec3 world_offset = vec3(dir.x, 0.0, dir.y) * s * wind_strength * f;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * world_offset;
}

void fragment() {
	vec3 col = use_instance_color ? srgb_to_linear(COLOR.rgb) : albedo.rgb;
	col *= mix(1.0 - tip_brighten * 0.6, 1.0 + tip_brighten, v_h);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (grass_normals) {
		// Light blades like the lawn (face up) so they never go dark on one side.
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	}
}
