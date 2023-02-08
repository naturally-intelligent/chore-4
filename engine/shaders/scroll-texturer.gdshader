shader_type canvas_item;

uniform sampler2D TEXTURE2;
uniform vec2 offset;
uniform float alpha;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;

	vec4 t1 = texture(TEXTURE, UV);
	vec2 UV2 = UV * (vec2(textureSize(TEXTURE, 0)) / 
	vec2(textureSize(TEXTURE2, 0))) - (offset / vec2(textureSize(TEXTURE2, 
0)));
    vec4 t2 = texture(TEXTURE2, UV2);
	if(UV2.x >= 0.0 && UV2.x <= 1.0 && UV2.y >= 0.0 && UV2.y <= 1.0) {
	    COLOR = vec4(mix(t1.rgb, t2.rgb, t2.a * alpha), t1.a);
	} else {
		COLOR = t1;
	}
}
