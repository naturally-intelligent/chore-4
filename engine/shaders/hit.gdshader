shader_type canvas_item;
render_mode unshaded;

uniform bool enabled = true;
uniform vec4 color : source_color;

void fragment()
{
	if(enabled) {
		vec4 pixel = texture(TEXTURE, UV);
		if(pixel.a > 0.0) {
			COLOR = color;
		} else {
			COLOR.a = 0.0;
		}
	}
}