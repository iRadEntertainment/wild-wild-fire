// NOTE: Shader automatically converted from Godot Engine 4.5.stable.mono's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D heat_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D burnt_map : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 color_burn : source_color;
uniform vec4 color_ambers : source_color;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float alpha_hash_scale : hint_range(0.0, 2.0, 0.01);
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);
varying vec3 uv1_triplanar_pos;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying flat ivec2 grid_pos;


float get_heat() {
	float heat = texture(heat_map, vec2(grid_pos)/128.0).r;
	return heat;
}


float get_burnt_ratio() {
	float burnt = texture(burnt_map, vec2(grid_pos)/128.0).r;
	return burnt;
}


void vertex() {
	grid_pos = ivec2(INSTANCE_CUSTOM.rg);
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
	vec4 noise_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	float heat = get_heat();
	float burnt_ratio = get_burnt_ratio();
	vec4 noise_col;
	noise_col.rgb = mix(color_burn.rgb, color_ambers.rgb, noise_tex.r * (heat - burnt_ratio));
	noise_col.rgb += mix(color_burn.rgb, color_ambers.rgb, noise_tex.r * (heat - burnt_ratio));
	noise_col.a = smoothstep(0.0, 1.0, (heat + burnt_ratio) * noise_tex.r);

	float metallic_tex = dot(triplanar_texture(texture_metallic, uv1_power_normal, uv1_triplanar_pos), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Emission: Enabled
	vec3 emission_tex = triplanar_texture(texture_emission, uv1_power_normal, uv1_triplanar_pos).rgb;
	// Emission Operator: Add
	EMISSION = noise_col.rgb * heat * emission_energy;
	//ALPHA *= smoothstep(noise_tex.r, 0.0, heat);
	//ALPHA_HASH_SCALE = alpha_hash_scale;
	
	ALBEDO.rgb = noise_col.rgb;
	ALPHA *= noise_col.a;
}
