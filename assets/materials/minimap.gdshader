shader_type canvas_item;
render_mode blend_add;

uniform int type;
uniform vec4 base_color : source_color;
uniform vec4 data_color : source_color;

void fragment() {
	vec4 sampled_col = texture(TEXTURE, UV);
	float data = 0.0;
	if (type == 1) { data = sampled_col.r;}
	else if (type == 2) { data = sampled_col.g;}
	else if (type == 3) { data = sampled_col.b;}
	else if (type == 4) { data = 1.0 - sampled_col.a;}
	
	COLOR = mix(base_color, data_color, data);
	//COLOR.a = base_color.a;
}
