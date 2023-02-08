shader_type canvas_item;

uniform float rotation=-0.5;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 rel = uv-vec2(0.5,0.5);
	float angle = length(rel)*(rotation+mod(TIME, 32.0)/16.0);
	mat2 rot = mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	rel = rot * rel;
	uv = clamp(rel + vec2(0.5,0.5),vec2(0,0),vec2(1,1));
	COLOR.rgb= textureLod(SCREEN_TEXTURE,uv,0.0).rgb;
}

