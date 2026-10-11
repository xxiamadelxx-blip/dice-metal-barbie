shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// This is VISUAL VERTEX DISPLACEMENT only. The StaticBody3D/Jolt floor does
// not move and face normals/values are never manipulated.
uniform sampler2D felt_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D felt_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec2 contact_center = vec2(0.0, 0.0);
uniform float impact_progress : hint_range(0.0, 1.0) = 1.0;
uniform float impact_strength : hint_range(0.0, 1.0) = 0.0;
varying float depression;
varying float edge_ripple;

void vertex() {
    vec2 dv = VERTEX.xz - contact_center;
    float distance = length(dv);
    float envelope = pow(1.0 - impact_progress, 2.0) * impact_strength;
    depression = exp(-distance * distance * 4.0) * envelope;
    float wave_front = 0.22 + impact_progress * 0.65;
    edge_ripple = exp(-pow((distance - wave_front) * 6.0, 2.0)) * envelope;
    // <1.2 cm visually; true collision geometry is completely static.
    VERTEX.y -= depression * 0.012;
}

void fragment() {
    vec3 textile = texture(felt_albedo, UV).rgb;
    // Local dark pile compression and subtle velvet sheen, no elastic rubber.
    ALBEDO = textile * (1.0 - depression * 0.20 + edge_ripple * 0.09);
    NORMAL_MAP = texture(felt_normal, UV).rgb;
    NORMAL_MAP_DEPTH = 0.31;
    METALLIC = 0.0;
    ROUGHNESS = 0.96;
    SPECULAR = 0.18;
}
