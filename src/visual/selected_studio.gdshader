shader_type sky;

// Static reflection lighting. Original panorama and all die materials stay intact.
// No TIME, POSITION or moving-light dependency: no per-frame cubemap rebuild.
uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform float neutral_fill : hint_range(0.0, 1.0) = 0.04;
uniform float roof_energy : hint_range(0.0, 1.0) = 0.12;

void sky() {
    float roof = pow(max(dot(EYEDIR, normalize(vec3(0.15, 1.0, 0.20))), 0.0), 8.0);
    COLOR = texture(panorama, SKY_COORDS).rgb + vec3(neutral_fill + roof_energy * roof);
}
