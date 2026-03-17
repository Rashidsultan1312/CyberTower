shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float glow_size : hint_range(0.0, 10.0) = 3.0;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.1) {
		float a = 0.0;
		for (float x = -glow_size; x <= glow_size; x += 1.0) {
			for (float y = -glow_size; y <= glow_size; y += 1.0) {
				vec2 off = vec2(x, y) / vec2(textureSize(TEXTURE, 0));
				a += texture(TEXTURE, UV + off).a;
			}
		}
		a /= (glow_size * 2.0 + 1.0) * (glow_size * 2.0 + 1.0);
		COLOR = vec4(glow_color.rgb, a * glow_intensity * glow_color.a);
	} else {
		COLOR = col;
	}
}
