shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.25;
uniform float softness : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float brightness = max(col.r, max(col.g, col.b));
	float alpha = smoothstep(threshold - softness, threshold + softness, brightness);
	COLOR = vec4(col.rgb, col.a * alpha);
}
