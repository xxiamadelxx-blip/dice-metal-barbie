shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 mineral_position;

void vertex() {
    mineral_position = VERTEX;
}

void fragment() {
    // Non-photographic but physically geometry-bound obsidian grain. Subtle,
    // never changes face numbering, collider, physical weight or die result.
    vec3 p = mineral_position;
    float marble = sin(p.x * 18.0 + p.z * 16.0
                      + 1.8 * sin(p.y * 13.0 + p.x * 4.0));
    float needle = pow(1.0 - abs(marble), 15.0);
    float micro = sin(p.x * 91.0 + p.z * 65.0) *
                  sin(p.y * 86.0 - p.x * 39.0);
    float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
    // A wide photographic softbox reflection is reconstructed from the true
    // rotating 3D normal, not the face number. Adjacent facets must read as
    // different planes even with the dark velvet stage and mobile GPU.
    float studio = pow(clamp(dot(normalize(NORMAL), normalize(vec3(-0.47, 0.78, 0.42))), 0.0, 1.0), 2.0);
    vec3 obsidian = vec3(0.043, 0.054, 0.073)
                    + needle * vec3(0.026, 0.028, 0.035)
                    + micro * vec3(0.006);
    ALBEDO = obsidian;
    METALLIC = 0.20;
    ROUGHNESS = clamp(0.15 + micro * 0.026, 0.11, 0.23);
    SPECULAR = 0.88;
    // Visible graphite-blue mineral under dark stage lighting. Without a
    // studio reflection probe, metallic black would be a featureless void.
    EMISSION = vec3(0.075, 0.089, 0.108)
               + needle * vec3(0.018, 0.020, 0.024)
               + rim * vec3(0.042, 0.048, 0.068)
               + studio * vec3(0.080, 0.074, 0.065);
}
