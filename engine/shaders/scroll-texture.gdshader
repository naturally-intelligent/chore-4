shader_type canvas_item;

uniform float speed;

void fragment() {
	//vec2 ps = TEXTURE_PIXEL_SIZE;
	vec2 offset = vec2(speed * TIME, 0);
	vec4 t1 = texture(TEXTURE, UV + offset);
    COLOR = t1;
}
