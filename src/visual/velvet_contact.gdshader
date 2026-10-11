shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Atelier felt: directional 3D nap, not concrete clouds. ALL rendering-only.
// Physically authoritative floor is a DIFFERENT, fixed Jolt StaticBody3D.
uniform sampler2D felt_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D felt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 contact_center = vec2(0.0, 0.0);
uniform float impact_progress : hint_range(0.0, 1.0) = 1.0;
uniform float impact_strength : hint_range(0.0, 1.0) = 0.0;

varying float depression;
varying float edge_ripple;
varying vec2 world_nap;

void vertex() {
    world_nap = VERTEX.xz;
    vec2 delta = VERTEX.xz - contact_center;
    float distance = length(delta);
    float envelope = pow(1.0 - impact_progress, 2.0) * impact_strength;
    depression = exp(-distance * distance * 4.0) * envelope;
    float wave_front = 0.22 + impact_progress * 0.65;
    edge_ripple = exp(-pow((distance - wave_front) * 6.0, 2.0)) * envelope;
    VERTEX.y -= depression * 0.012;
}

void fragment() {
    // A repeated real 256px fiber texture rather than stretching noise over
    // the entire tray. Subtle guided 'pile' striping is intentionally visible
    // at 720px with anti-aliased details, without silk/gloss or concrete spots.
    vec2 tile_uv = UV * vec2(2.7, 4.1);
    vec3 fibers = texture(felt_albedo, tile_uv).rgb;
    float pile = sin(world_nap.y * 17.0 + sin(world_nap.x * 2.9) * 0.44);
    float cross_pile = sin(world_nap.x * 72.0 + world_nap.y * 5.5);
    float aa = clamp(1.0 / (1.0 + fwidth(world_nap.x * 72.0) * 2.0),0.0,1.0);
    float brushed = 0.94 + pile * 0.042 + cross_pile * 0.032 * aa;
    // Black-green charcoal, restrained aged-jade nap. Stop the previous
    // blue-grey speckled slab from reading as low-poly concrete.
    ALBEDO = fibers * vec3(0.83, 1.08, 0.89) * brushed;
    ALBEDO *= (1.0 - depression * 0.21 + edge_ripple * 0.09);
    NORMAL_MAP = texture(felt_normal, tile_uv).rgb;
    NORMAL_MAP_DEPTH = 0.53;
    METALLIC = 0.0;
    ROUGHNESS = 0.99;
    SPECULAR = 0.13;
    // Small velvet retroreflection; never emit a flat glowing plane.
    float grazing = pow(1.0 - clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),2.3);
    EMISSION = vec3(0.028,0.047,0.031) * grazing * 0.22;
}
