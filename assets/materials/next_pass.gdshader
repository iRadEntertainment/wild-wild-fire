// NOTE: Shader automatically converted from Godot Engine 4.5.stable.mono's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, cull_back;

uniform ivec2 fire_img_size = ivec2(128);
uniform sampler2D firesim_output : filter_nearest;
uniform vec4 color_burn : source_color;
uniform vec4 color_ambers : source_color;
uniform vec4 color_wet : source_color;
uniform float burnt_to_heat_ratio : hint_range(0.5, 1.1, 0.001) = 0.96;
uniform float burn_spread : hint_range(0.0, 10.0, 0.01) = 2.0;
uniform float ambers_spread : hint_range(0.0, 3.0, 0.01) = 0.5;

uniform sampler2D noise_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float alpha_hash_scale : hint_range(0.0, 2.0, 0.01);
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying flat ivec2 grid_pos;
varying flat vec2 grid_pos_norm;

// Fire sim Output Image
float get_heat() { return texture(firesim_output, grid_pos_norm).r; }
float get_moisture_internal() { return texture(firesim_output, grid_pos_norm).g; }
float get_moisture_external() { return texture(firesim_output, grid_pos_norm).b; }
float get_burnt() { return 1.0 - texture(firesim_output, grid_pos_norm).a; }



void vertex() {
	grid_pos = ivec2(INSTANCE_CUSTOM.rg);
	grid_pos_norm = vec2(grid_pos)/vec2(fire_img_size);
	
	vec3 normal = NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);

	// UV1 Triplanar: Enabled
	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	float noise_value = triplanar_texture(noise_tex, uv1_power_normal, uv1_triplanar_pos).r;
	//noise_value = (noise_value * 2.0) - 1.0;
	//vec4 noise_tex = texture(noise_tex, UV);
	float burnt = clamp(get_burnt(), 0.0, 1.0);
	float heat = clamp(get_heat(), 0.0, 1.0);
	float moisture_int = get_moisture_internal();
	float moisture_ext = get_moisture_external();
	float tot_moisture = (moisture_ext + moisture_int);
	
	vec4 burnt_col = color_burn;
	burnt_col.a = burnt * mix(0.6, 0.8, noise_value * burn_spread);
	burnt_col.a *= color_burn.a;
	vec4 heat_col = color_ambers;
	heat_col.a = (heat - burnt * burnt_to_heat_ratio) * smoothstep(0.0, 1.0, pow(noise_value, heat/ambers_spread));
	vec4 wet_col = color_wet * tot_moisture;
	wet_col.a = moisture_ext * mix(0.0, 1.0, 1.0 - noise_value);
	wet_col.a = min(color_wet.a, wet_col.a);
	
	METALLIC = tot_moisture * metallic;
	SPECULAR = tot_moisture * specular;
	ROUGHNESS = mix(1.0, 0.2, moisture_ext) * roughness;
	vec3 emission_amt = color_ambers.rgb * emission_energy;
	emission_amt *= heat_col.a;
	EMISSION = clamp(emission_amt, vec3(0.0), vec3(10.0));
	
	vec3 final_col = mix(wet_col.rgb, burnt_col.rgb, burnt_col.a);
	final_col += heat_col.rgb * heat_col.a;
	ALBEDO.rgb = clamp(final_col, vec3(0.0), vec3(1.0));
	ALPHA = max(max(burnt_col.a, heat_col.a), wet_col.a);
	ALPHA = clamp(ALPHA, 0.0, 1.0);
}
