shader_type spatial;
render_mode blend_mix, cull_front, unshaded, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float size : hint_range(1.0, 1.5, 0.01) = 1.03;

// 0 = hidden. > 0 = visible; acts as the opacity of the outline.
// The shell is always inflated to a CONSTANT size when visible, so animating
// `on` fades the outline in/out instead of scaling the geometry.
uniform float on = 0.0;

void vertex() {
	VERTEX *= mix(0.0, size, step(0.001, on));
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a * clamp(on, 0.0, 1.0);
}
