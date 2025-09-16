shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D heightmap : source_color, filter_linear, repeat_disable;
uniform float height_scale = 20.0; // meters per 1.0 unit along +Y


float decode_height(vec3 rgb) {
	vec3 C = rgb * 255.0;
	return (C.r * 256.0 + C.g + C.b / 256.0) - 32768.0;
}

void vertex() {
	float meters = decode_height(texture(heightmap, UV).rgb);
	VERTEX.y -= meters / height_scale; // larger height_scale flattens terrain; smaller exaggerates
}