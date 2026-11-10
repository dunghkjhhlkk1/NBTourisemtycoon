shader_type canvas_item;
render_mode unshaded;
varying vec2 p;
void vertex() { p = VERTEX; }
float waves(vec2 v) {
	return sin(v.y*0.34+sin(v.x*0.078)*1.6)
		* sin(v.x*0.031+v.y*0.12)
		* cos(v.x*0.091-v.y*0.17);
}
void fragment() {
	float glow = 0.5 + 0.5*sin(p.x*0.009+p.y*0.016);
	vec3 water = mix(vec3(0.02,0.28,0.30),vec3(0.04,0.53,0.47),glow);
	float ripple = smoothstep(0.31,0.85,waves(p+vec2(TIME*9.0,TIME*2.4)));
	COLOR = vec4(water+vec3(0.25,0.33,0.24)*ripple,1.0);
}
