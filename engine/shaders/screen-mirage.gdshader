shader_type canvas_item;

uniform float frequency=60;
uniform float depth = 0.005;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y*frequency+TIME)*depth;
	uv.x = clamp(uv.x,0,1);
	//uv.x /= SCREEN_PIXEL_SIZE.x;
	//uv.x = ceil(uv.x);
	//uv.x *= SCREEN_PIXEL_SIZE.x;
	//uv.x *= TEXTURE_PIXEL_SIZE.x;
	//vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	//uv.x *= 320.0;
	//uv.x = floor(uv.x);
	//uv.x /= 320.0;
	vec3 c = texture(SCREEN_TEXTURE, uv).rgb;
	//vec3 c = textureLod(SCREEN_TEXTURE,uv,0.0).rgb;
	
	
	COLOR.rgb=c;
}

