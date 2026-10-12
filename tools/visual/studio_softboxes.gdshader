shader_type sky;

// Free, procedurally authored studio reflection environment.
// Used ONLY for exact-GLB lookdev; not a background screenshot or fake dice.
// A specular dark material needs a shaped surrounding radiance field.
void sky() {
    vec3 d = normalize(EYEDIR);
    float upward = clamp(0.5 + 0.5 * d.y, 0.0, 1.0);
    vec3 charcoal = mix(vec3(0.030, 0.045, 0.052), vec3(0.083, 0.115, 0.131), upward);
    vec3 key_axis = normalize(vec3(-0.55, 0.69, 0.48));
    vec3 rim_axis = normalize(vec3(0.73, 0.42, -0.54));
    float warm_panel = pow(max(dot(d, key_axis), 0.0), 14.0);
    float cool_panel = pow(max(dot(d, rim_axis), 0.0), 22.0);
    COLOR = charcoal + vec3(1.65, 1.30, 0.94) * warm_panel + vec3(0.52, 0.76, 1.15) * cool_panel;
}
