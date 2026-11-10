shader_type canvas_item;

varying vec2 ground_position;

void vertex() {
	ground_position = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void fragment() {
	float patches = noise(ground_position * 0.012);
	float grass = noise(ground_position * 0.075);
	float freckles = step(0.86, hash(floor(ground_position * 0.24)));
	vec3 shaded = mix(vec3(0.19, 0.29, 0.11), vec3(0.38, 0.48, 0.18), patches);
	shaded += (grass - 0.5) * 0.095 + freckles * 0.025;
	COLOR = vec4(shaded, 1.0);
}
