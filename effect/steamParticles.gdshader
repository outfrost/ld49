shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,unshaded,specular_disabled;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;
uniform bool particles_anim_loop;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying float lifetime;

void vertex() {
	// Stuff Godot generated to make this a particle billboard
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	mat4 mat_world = mat4(normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),WORLD_MATRIX[3]);
	mat_world = mat_world * mat4( vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM.z * float(particle_total_frames));
	if (!particles_anim_loop) {
		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);
	} else {
		particle_frame = mod(particle_frame, particle_total_frames);
	}	UV /= vec2(h_frames, v_frames);
	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor(particle_frame / h_frames) / v_frames);
	
	lifetime = INSTANCE_CUSTOM.y;
}

void fragment() {
	ALBEDO = albedo.rgb;
	float smooth_blob = clamp(1.0 - smoothstep(0.0, 1.0, (2.25 * distance(UV, vec2(0.5, 0.5)))), 0.0, 1.0);
	float fade = clamp(-2.0 * lifetime + 2.0, 0.0, 1.0);
	ALPHA = albedo.a * smooth_blob * fade;
}
