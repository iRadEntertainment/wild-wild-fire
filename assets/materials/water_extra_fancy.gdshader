shader_type spatial;
render_mode shadows_disabled;

uniform vec4 main_color : source_color;
uniform vec4 intersection_color : source_color;
uniform float intersection_max_threshold = 0.1;
uniform sampler2D displ_tex;
uniform float displ_amount = 0.1;
uniform float near = 0.05;
uniform float far = 4000.0;
uniform sampler2D depth_texture: hint_depth_texture;
uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
const float uv_scale = 3.0;

void vertex()
{
	float height = texture(displ_tex, (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz/8.0).x;
	COLOR = vec4(height);
	NORMAL = vec3(0, 1, 0);
	//if (sway)
	{
		float time = (TIME*1.5) + (6.28318);
		VERTEX.y += sin(time + height*100.0) * 0.05;
	}
}

float linearize(float c_depth) {
	c_depth = 2.0 * c_depth - 1.0;
	return near * far / (far + c_depth * (near - far));
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment()
{
	//EMISSION = vec3(0.0, 0.0, 0.5);
	METALLIC = 0.105;
	ROUGHNESS = 0.01;
	SPECULAR = 0.00;
	NORMAL_MAP = mix(texture(texture_normal,UV * uv_scale + TIME / 500.0).rgb, texture(texture_normal2,UV * uv_scale - TIME / 500.0).rgb, 0.5);
	float fresnel = fresnel(2.0, NORMAL, VIEW);
	vec3 surface_color = mix(main_color.rgb, main_color.rgb * 10.0, fresnel); // Interpolate albedo values by frensel
	ALBEDO = mix(surface_color, surface_color * 2.0, NORMAL_MAP.b);

	float zdepth = linearize(texture(depth_texture, SCREEN_UV).r);
	float zpos = linearize(FRAGCOORD.z);
	float diff = zdepth - zpos;

	vec2 displ = texture(displ_tex, UV * uv_scale * 4.0 - TIME / 1000.0).rg;
	displ = ((displ * 2.0) - 1.0) * displ_amount;
	diff += displ.x;

	ALBEDO = mix(ALBEDO * 10.0, ALBEDO, step(intersection_max_threshold, diff));
	ALBEDO *= texture(displ_tex, UV - TIME / 100.0).r + 1.0;

	float depth_t = texture(depth_texture, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_t + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth+VERTEX.z + 4.75) * -2.0);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(main_color.rgb * 1000.0, main_color.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);
	//color = depth_color * 0.25;
	ALBEDO = mix(ALBEDO, color, 0.75);

	//ALBEDO = clamp(ALBEDO + depth_color_adj,vec3(0.0),vec3(1.0));
	//ALPHA = main_color.a;
}
