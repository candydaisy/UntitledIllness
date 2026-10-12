shader_type canvas_item;
// Recolors greyscale art (the white butterflies in sideart.png) with one color.
// Black stays black, grey becomes a darker shade of the tint, and the
// brightest parts fade toward white so the wings keep their highlights.

uniform vec4 tint : source_color = vec4(0.35, 0.5, 1.0, 1.0);
uniform float highlight : hint_range(0.0, 1.0) = 0.35; // how white the brightest parts get

void fragment() {
	float lum = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = tint.rgb * lum;
	col = mix(col, vec3(1.0), smoothstep(0.75, 1.0, lum) * highlight);
	COLOR = vec4(col, COLOR.a * tint.a);
}
