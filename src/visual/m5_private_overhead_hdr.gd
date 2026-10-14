extends RefCounted
## Optional physically reflected overhead studio. It changes illumination only:
## original licensed BlenderKit stone base, normal, roughness and 20 gold meshes
## are NEVER repainted. Disabled by default and verified fail-closed.
const M5Art = preload("res://src/dice/m5_original_obsidian_art.gd")
const FLAG := "dice/m5/enable_overhead_gloss_hdr"
const SOURCE := "res://src/assets/private/m5_overhead_cap_softbox.hdr"
const SOURCE_SHA256 := "4d4b5adb93dc5785889d505de18d48a77a45ece3a91f60786bf403c1e5dffcdc"

static func install(stage: Node3D) -> bool:
    if not M5Art.enabled() or not bool(ProjectSettings.get_setting(FLAG,false)):
        return false
    if not FileAccess.file_exists(M5Art.PRIVATE_SOURCE) or FileAccess.get_sha256(M5Art.PRIVATE_SOURCE)!=M5Art.PRIVATE_SHA256:
        push_warning("M5 original 500k model absent/wrong SHA; studio fallback")
        return false
    if not FileAccess.file_exists(SOURCE) or FileAccess.get_sha256(SOURCE)!=SOURCE_SHA256:
        push_warning("M5 unverified overhead HDR source; original lighting fallback")
        return false
    if not ResourceLoader.exists(SOURCE):
        push_warning("M5 overhead studio HDR missing Godot import; keep original sky")
        return false
    var panorama := load(SOURCE) as Texture2D
    if panorama == null:
        push_warning("M5 private overhead HDR invalid; original sky preserved")
        return false
    var env_node: WorldEnvironment=null
    for child in stage.get_children():
        if child is WorldEnvironment:
            env_node=child as WorldEnvironment
            break
    if env_node==null or env_node.environment==null:
        push_warning("M5 overhead HDR cannot find original WorldEnvironment")
        return false
    var sky := Sky.new()
    sky.radiance_size=Sky.RADIANCE_SIZE_256
    var mat := PanoramaSkyMaterial.new()
    mat.panorama=panorama
    mat.energy_multiplier=1.0
    sky.sky_material=mat
    # The camera must never see bright cards or a tilted horizon.
    env_node.environment.sky=sky
    env_node.environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
    print("DICE_M5_PRIVATE_OVERHEAD_GLASS_STUDIO source=",SOURCE,
        " map_sha=",FileAccess.get_sha256(SOURCE)," radiance=256")
    return true
