shader_type canvas_item;
// Palette-swap only the pack's cyan/blue pixels. Paper, brown ink,
// woodgrain and gold remain original. Preserves original pixel shading.
void fragment() {
	vec4 src = texture(TEXTURE, UV) * COLOR;
	float blue_dominance = src.b - src.r;
	float cyan_dominance = src.g - src.r;
	float mask_blue = smoothstep(0.025, 0.13, blue_dominance) *
		smoothstep(-0.015, 0.085, cyan_dominance);
	float lightness = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 oxblood = vec3(lightness * 1.40, lightness * 0.37, lightness * 0.43);
	src.rgb = mix(src.rgb, oxblood, mask_blue);
	COLOR = src;
}
