shader_type canvas_item;
render_mode unshaded;

uniform sampler2D banks : filter_linear, repeat_disable;
uniform float ground_y_scale;

varying vec2 map_point;
varying vec2 painted_point;

void vertex() {
	float y = VERTEX.y / ground_y_scale;
	map_point = vec2(40.0 * VERTEX.x - 56.0 * y, 24.0 * VERTEX.x + 72.0 * y) / 4224.0;
	painted_point = VERTEX;
}

float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float grain(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 p = painted_point;
	vec2 edges = texture(banks, vec2(map_point.x / 48.0, 0.5)).rg * 48.0;
	float roughness = (grain(p * 0.037) - 0.5) * 0.35;
	float depth = min(map_point.y - edges.x, edges.y - map_point.y) + roughness;

	float meadow = grain(p * 0.006) * 0.65 + grain(p * 0.049) * 0.25 + grain(p * 0.23) * 0.1;
	vec3 land = mix(vec3(0.12, 0.24, 0.10), vec3(0.49, 0.60, 0.21), meadow);
	float beach = smoothstep(-0.76, 0.05, depth);
	land = mix(land, mix(vec3(0.31, 0.31, 0.20), vec3(0.65, 0.58, 0.35), meadow), beach);

	vec2 ripple = p * vec2(0.032, 0.21);
	float current = grain(ripple + vec2(TIME * 0.27, 0.0));
	float broken_light = grain(p * vec2(0.012, 0.08));
	float glint = smoothstep(0.65, 0.89, current) * smoothstep(0.36, 0.81, broken_light);
	vec3 water = mix(vec3(0.025, 0.23, 0.26), vec3(0.05, 0.55, 0.51), grain(p * 0.012) * 0.78 + current * 0.22);
	water += vec3(0.40, 0.57, 0.49) * glint * 0.8;
	water = mix(vec3(0.19, 0.40, 0.31), water, smoothstep(0.0, 0.65, depth));
	COLOR = vec4(mix(land, water, smoothstep(-0.05, 0.12, depth)), 1.0);
}
