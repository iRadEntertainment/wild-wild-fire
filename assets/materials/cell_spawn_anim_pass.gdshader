shader_type spatial;

uniform ivec2 grid_size = ivec2(128, 128);
uniform sampler2D vertical_shift_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float vertical_shift : hint_range(0.0, 100.0, 0.1) = 0.0;

varying flat ivec2 grid_pos;
varying vec2 grid_uv;
varying vec3 instance_scale;
varying float spawn_amt;


void vertex() {
	instance_scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	
	grid_pos.x = INSTANCE_ID % grid_size.x;
	grid_pos.y =INSTANCE_ID/grid_size.x;
	grid_uv = vec2(grid_pos) / vec2(grid_size);
	spawn_amt = texture(vertical_shift_tex, grid_uv).r;
	VERTEX.y -= smoothstep(0, vertical_shift, spawn_amt) / instance_scale.y;
	//VERTEX.y *= smoothstep(0, vertical_shift, spawn_amt);
}
