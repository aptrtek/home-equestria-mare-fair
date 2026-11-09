shader_type spatial;
render_mode cull_disabled;
// Vertical gores, matching the visible Mare Fair balloon
// (https://2025.marefair.org/_astro/mf_desktop.iPluWSMU_EDpGb.png).
// Stripes follow the angle around the model, so they need no particular UVs.

uniform vec4 red_color : source_color = vec4(0.941176, 0.282353, 0.313725, 1.0);
uniform vec4 blue_color : source_color = vec4(0.490196, 0.705882, 0.878431, 1.0);
uniform float stripe_count = 8.0;
uniform float roughness_amount : hint_range(0.0, 1.0) = 0.78;
// 1 for the tent: a woven canvas look with stitched seams where the colours meet. Local units
// are metres there; the balloon leaves this at 0.
uniform float canvas = 0.0;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float turn = atan(local_position.z, local_position.x) / TAU + 0.5;
	float band = fract(turn * stripe_count);
	vec3 color = band < 0.5 ? red_color.rgb : blue_color.rgb;
	float rough = roughness_amount;
	if (canvas > 0.5) {
		float across = local_position.x + local_position.z;
		float weave = sin(across * 260.0) * sin(local_position.y * 260.0);
		float slub = sin(across * 23.0 + local_position.y * 7.0) * sin(local_position.y * 31.0 - across * 5.0);
		color *= 1.0 + 0.045 * weave + 0.03 * slub;
		// A seam where each band meets the next, stitched with short dashes.
		float edge = min(abs(band - 0.5), min(band, 1.0 - band)) * TAU * length(local_position.xz) / stripe_count;
		float stitch = step(0.5, fract((local_position.y + across * 0.3) * 9.0));
		color *= edge < 0.025 ? 0.78 : (edge < 0.05 ? 0.92 + 0.08 * stitch : 1.0);
		// A darker hem along the bottom.
		color *= local_position.y < 0.12 ? 0.82 : 1.0;
		rough = 0.92;
	}
	ALBEDO = color;
	ROUGHNESS = rough;
}
