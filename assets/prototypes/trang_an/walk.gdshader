shader_type canvas_item;
uniform float stride = 0.0;
uniform float moving = 0.0;
void fragment() {
	vec2 uv = UV;
	float legs = smoothstep(0.63, 0.92, uv.y) * moving;
	float side = smoothstep(0.48, 0.52, uv.x) * 2.0 - 1.0;
	uv.x += sin(stride) * 0.025 * legs * side;
	uv.y += abs(sin(stride)) * 0.014 * legs;
	COLOR = texture(TEXTURE, uv) * COLOR;
}
