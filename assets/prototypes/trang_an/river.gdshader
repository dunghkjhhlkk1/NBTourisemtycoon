shader_type canvas_item;
render_mode unshaded;
varying vec2 p;
void vertex() {
	p = VERTEX;
}
float hash(vec2 a) {
	vec3 q = fract(a.xyx * .1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float noise2(vec2 a) {
	vec2 i = floor(a);
	vec2 f = fract(a);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
void fragment() {
	float bank = 705.0 - p.x*.109 + 30.0*sin((p.x-170.0)*.005) + 16.0*sin(p.x*.011);
	float depth = p.y-bank;
	float mottling = noise2(p*.026);
	vec3 land = mix(vec3(.17,.34,.14),vec3(.44,.57,.23),mottling);
	land = mix(land, vec3(.56,.51,.31), smoothstep(-26.0, 0.0, depth)*.78);
	float ripple = noise2(p*vec2(.043,.25)+vec2(TIME*.54,0));
	float shimmer = smoothstep(.64,.88,ripple)*.55;
	vec3 water = mix(vec3(.04,.31,.33),vec3(.11,.65,.57),mottling);
	water += shimmer * vec3(.31,.48,.37);
	water = mix(vec3(.31,.52,.41),water,smoothstep(0.0,62.0,depth));
	COLOR = vec4(mix(land,water,smoothstep(-1.0,4.0,depth)),1.0);
}
