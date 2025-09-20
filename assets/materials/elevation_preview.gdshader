shader_type spatial;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D texture_heightmap : source_color, filter_linear_mipmap, repeat_disable;
uniform float meters_per_unit : hint_range(0.1, 5000.0, 0.1) = 256.0;
uniform float exaggeration : hint_range(0.1, 20.0, 0.1) = 1.0;
uniform float center_meters : hint_range(-40000.0, 0.0, 0.1) = -20000.0;


float decode_height(vec3 rgb) {
	vec3 C = rgb * 255.0;
	return (C.r * 256.0 + C.g + C.b / 256.0);// - 32768.0;
}

void vertex() {
	float meters = decode_height(texture(texture_heightmap, UV).rgb);
	float relative = (meters - center_meters) * exaggeration;
	VERTEX.y = relative / meters_per_unit;
}

void fragment() {
	ALBEDO = texture(texture_albedo, UV).rgb; // debug
	//ALBEDO = texture(texture_heightmap, UV).rgb; // debug
}
