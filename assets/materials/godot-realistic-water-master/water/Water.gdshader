// Water / Caustics shader (Godot 4.5)
// Ported & cleaned from the original UnionBytes shader.
// Key changes vs 3.x version:
// - Foam/contact uses scene_depth vs FRAGCOORD.z (same space) → no "foam everywhere".
// - Absorption uses view-space thickness reconstructed with INV_PROJECTION_MATRIX.
// - Use WORLD/VIEW built-ins instead of MODELVIEW, and remove legacy depth math.
// - 'foam_level' now controls shoreline width/sensitivity.

shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx, blend_mix;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Wave settings
uniform float wave_speed = 0.5;                       // Speed scale for the waves
uniform vec4  wave_a = vec4(1.0, 1.0, 0.35, 3.0);     // xy=dir, z=steepness, w=length
uniform vec4  wave_b = vec4(1.0, 0.6, 0.30, 1.55);
uniform vec4  wave_c = vec4(1.0, 1.3, 0.25, 0.90);

// Surface samplers
uniform vec2  sampler_scale = vec2(0.25, 0.25);
uniform vec2  sampler_direction = vec2(0.05, 0.04);

uniform sampler2D uv_sampler : hint_anisotropy;       // Flow/noise to shift normal UVs
uniform vec2  uv_sampler_scale = vec2(0.25, 0.25);
uniform float uv_sampler_strength= 0.04;

uniform sampler2D normalmap_a_sampler : hint_normal;
uniform sampler2D normalmap_b_sampler : hint_normal;

uniform sampler2D foam_sampler : hint_default_black;  // Foam noise/tiling
uniform float foam_level = 0.5;                       // 0..1: shoreline width/sensitivity

// Volume / absorption
uniform float refraction = 0.075;

uniform vec4  color_deep : source_color;           // deep water color
uniform vec4  color_shallow : source_color;           // shallow water color
uniform float beers_law = 2.0;                        // absorption strength
uniform float depth_offset = 0.0;                     // meters added to column (fine-tune)

// Caustics (projected)
uniform mat4  projector;
uniform sampler2DArray caustic_sampler : hint_default_black;

varying vec3 V_SURFACE_WORLD;


vec4 wave(vec4 parameter, vec2 position, float time, inout vec3 tangent, inout vec3 binormal) {
	float wave_steepness = parameter.z;
	float wave_length = parameter.w;
	
	float k = 2.0 * 3.14159265359 / wave_length;
	float c = sqrt(9.8 / k);
	vec2  d = normalize(parameter.xy);
	float f = k * (dot(d, position) - c * time);
	float a = wave_steepness / k;
	
	tangent  += normalize(vec3(1.0 - d.x * d.x * (wave_steepness * sin(f)),
		d.x * (wave_steepness * cos(f)),
		-d.x * d.y * (wave_steepness * sin(f))));
    binormal += normalize(vec3(-d.x * d.y * (wave_steepness * sin(f)),
		d.y * (wave_steepness * cos(f)),
		1.0 - d.y * d.y * (wave_steepness * sin(f))));
	
	return vec4(d.x * (a * cos(f)), a * sin(f) * 0.25, d.y * (a * cos(f)), 0.0);
}


float distance_to_underlying_world(vec2 sample_uv, vec3 ground_world) {
	sample_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));
	
	float scene_depth = texture(DEPTH_TEXTURE, sample_uv).r;
	if (scene_depth <= 0.0001) {
		return 0.0; // no geometry behind
	}
	return distance(V_SURFACE_WORLD, ground_world);
}


void vertex() {
	float time = TIME * wave_speed;
	
	vec4 vtx = vec4(VERTEX, 1.0);
	vec3 world_pos = (MODEL_MATRIX * vtx).xyz;
	
	vec3 tang = vec3(0.0);
	vec3 bin  = vec3(0.0);
	
	vtx += wave(wave_a, world_pos.xz, time, tang, bin);
	vtx += wave(wave_b, world_pos.xz, time, tang, bin);
	vtx += wave(wave_c, world_pos.xz, time, tang, bin);
	
	// Provide a consistent TBN affected by waves
	TANGENT = tang;
	BINORMAL = bin;
	NORMAL = normalize(cross(BINORMAL, TANGENT));
	
	// Tile UVs by world XZ so the surface doesn't stretch with mesh topology
	UV = vtx.xz * sampler_scale;
	
	vec4 displaced_world = MODEL_MATRIX * vec4(vtx.xyz, 1.0);
	V_SURFACE_WORLD = displaced_world.xyz;
	
	VERTEX = vtx.xyz;
}


void fragment() {
	// Flow-UVs for animated normals
	vec2 uv_offset = sampler_direction * TIME;
	vec2 flow_uv = UV * uv_sampler_scale + uv_offset;
	vec2 flow_shift = uv_sampler_strength * (texture(uv_sampler, flow_uv).rg * 2.0 - 1.0);
	vec2 uv = UV + flow_shift;
	
	// Combine normal maps
	vec3 nm = texture(normalmap_a_sampler, uv - uv_offset * 2.0).rgb * 0.75;
		nm+= texture(normalmap_b_sampler, uv + uv_offset      ).rgb * 0.25;
	
	// Build perturbed normal in world/object space using the TBN we set in vertex
	vec3 n = nm * 2.0 - 1.0;
	vec3 perturbed = normalize(TANGENT * n.x + BINORMAL * n.y + NORMAL * n.z);
	
	// Refraction: offset screen UV by the perturbed normal, scaled by current depth
	float depth_scale = max(0.001, FRAGCOORD.z); // avoid div by zero; shallower → stronger offset
	
	vec2 refraction_offset = (perturbed.xy * refraction) / depth_scale;
	refraction_offset = clamp(refraction_offset, vec2(-0.01), vec2(0.01));
	vec2 ref_uv = SCREEN_UV + refraction_offset;
	
	// Gradients for stable sampling
	vec2 duv_dx = dFdx(ref_uv);
	vec2 duv_dy = dFdy(ref_uv);
	
	// Depths in the SAME space (0..1) for contact / shoreline
	float scene_depth = textureGrad(DEPTH_TEXTURE, ref_uv, duv_dx, duv_dy).r;
	//float scene_depth = texture(DEPTH_TEXTURE, ref_uv).r; // depth of ground/geometry under water at refracted UV
	float my_depth = FRAGCOORD.z; // depth of this water pixel
	bool has_depth = scene_depth < 0.999;
	
	// Positive near shore/contacts, approaches 0 in deep water
	// foam_level scales sensitivity/width (0.2 narrow, 1.0 wide/strong)
	float foam_sensitivity = mix(20.0, 200.0, clamp(foam_level, 0.0, 1.0));
	float depth_diff = has_depth ? clamp((my_depth - scene_depth) * foam_sensitivity, 0.0, 1.0) : 0.0;
	
	// View-space thickness for absorption (Beer's law)
	// Back-project ground (at refracted UV)
	vec3 ndc_ground = vec3(ref_uv * 2.0 - 1.0, scene_depth * 2.0 - 1.0);
	vec4 vp_ground  = INV_PROJECTION_MATRIX * vec4(ndc_ground, 1.0);
	float ground_view_z = vp_ground.z / vp_ground.w; // negative in front of camera
	
	// Back-project surface (this fragment)
	vec3 ndc_surface = vec3(SCREEN_UV * 2.0 - 1.0, my_depth * 2.0 - 1.0);
	vec4 vp_surface  = INV_PROJECTION_MATRIX * vec4(ndc_surface, 1.0);
	float surface_view_z = vp_surface.z / vp_surface.w; // also negative
	
	// Positive thickness in view space (meters-ish, depends on projection)
	float column = max(0.0, surface_view_z - ground_view_z + depth_offset);
	
	// 0..1 blend weight, steeper near shallow water
	float depth_blend = clamp(1.0 - exp(-beers_law * column), 0.0, 1.0);
	float depth_blend_pow = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	// Roughness-driven extra blur (scale the gradients)
	float local_roughness = 0.2 + depth_blend_pow * 0.4;
	float lod_bias = mix(0.0, 1.5, local_roughness);
	duv_dx *= exp2(lod_bias);
	duv_dy *= exp2(lod_bias);
	
	// Screen color & dyeing by water color
	vec3 screen_color = textureGrad(SCREEN_TEXTURE, ref_uv, duv_dx, duv_dy).rgb;
	//vec3 screen_color = textureLod(SCREEN_TEXTURE, ref_uv, depth_blend_pow * 2.5).rgb;
	vec3 dye_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_pow);
	vec3 color = mix(screen_color * dye_color, dye_color * 0.25, depth_blend_pow * 0.5);
	
	// Caustics (simple projected variant) 
	// Convert screen → world → local
	vec4 world_from_screen = INV_VIEW_MATRIX * vec4(ndc_ground, 1.0);
	world_from_screen /= world_from_screen.w;
	vec4 local_pos = INV_PROJECTION_MATRIX * world_from_screen;
	
	// Faux projector UVs (tune the scale to your scene)
	vec2 caustic_uv = local_pos.xz * 300.0 / 1024.0 + 0.5;
	float frame = mod(TIME * 14.0, 16.0);
	vec4 caustic = texture(caustic_sampler, vec3(caustic_uv, frame));
	
	color *= 1.0 + pow(max(caustic.r, 0.0), 1.5) * (1.0 - depth_blend) * 6.0;
	
	// Foam where the floor/geometry is close
	if (depth_diff > 0.0) {
		float foam_noise = clamp(pow(texture(foam_sampler, (uv * 4.0) - uv_offset).r, 10.0) * 40.0, 0.0, 0.2);
		float foam_edge = pow(depth_diff, 3.0);
		float foam_mix = clamp(foam_edge * foam_noise * 0.8, 0.0, 1.0);
		color = mix(color, vec3(1.0), foam_mix);
	}
	
	//ALBEDO = vec3(depth_diff, 0.0, 0.0);
	//ALBEDO = has_depth ? vec3(0,1,0) : vec3(1,0,0);
	// Outputs
	ALBEDO = color;
	METALLIC = 0.1;
	ROUGHNESS = 0.2;
	SPECULAR = 0.2 + depth_blend_pow * 0.4;
	NORMAL = perturbed;
}
