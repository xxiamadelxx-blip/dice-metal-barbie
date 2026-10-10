extends RefCounted
## Die-origin 3D pulse for authentic, *settled* D20 critical faces only.
## Purely visual: no collision, forces, dice result or physics material changes.

static func spawn(die: RigidBody3D, sides: int, result: int) -> Node3D:
    if sides != 20 or (result != 1 and result != 20):
        return null
    if not is_instance_valid(die) or not die.is_inside_tree():
        return null
    var previous := die.get_node_or_null("CriticalDiceAura") as Node3D
    if previous != null:
        return previous
    var aura := Node3D.new()
    aura.name = "CriticalDiceAura"
    die.add_child(aura)
    # D20 settles on arbitrary orientation: the shockwave stays horizontal
    # in world-space, above the die, while its origin follows the actual die.
    aura.global_transform = Transform3D(Basis.IDENTITY, die.global_position + Vector3(0, 0.55, 0))
    var color := Color(1.0, 0.70, 0.22, 0.74) if result == 20 else Color(1.0, 0.18, 0.25, 0.72)

    for index in range(2):
        var ring := MeshInstance3D.new()
        ring.name = "GoldPulse" if result == 20 else "CrimsonPulse"
        var torus := TorusMesh.new()
        torus.inner_radius = 0.74 if index == 0 else 0.68
        torus.outer_radius = 0.795 if index == 0 else 0.715
        ring.mesh = torus
        var material := StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.albedo_color = color
        material.emission_enabled = true
        material.emission = Color(color.r, color.g, color.b)
        material.emission_energy_multiplier = 1.8 if result == 20 else 1.4
        ring.material_override = material
        ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        ring.scale = Vector3(0.72, 1, 0.72) if index == 0 else Vector3(0.56, 1, 0.56)
        ring.position.y = 0.03 * index
        aura.add_child(ring)

    var lamp := OmniLight3D.new()
    lamp.name = "DieOriginFlash"
    lamp.light_color = Color(color.r, color.g, color.b)
    lamp.omni_range = 3.0
    lamp.light_energy = 2.0 if result == 20 else 1.65
    lamp.shadow_enabled = false
    aura.add_child(lamp)

    # A pair of expanding toroidal fronts reads as an aura emerging from
    # the stone, without particles/texture fetches on the offline Android GPU.
    var animation := aura.create_tween()
    animation.set_parallel(true)
    var rings := aura.get_children()
    var outer := rings[0] as MeshInstance3D
    var inner := rings[1] as MeshInstance3D
    animation.tween_property(outer, "scale", Vector3(2.55, 1, 2.55), 0.90).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    animation.tween_property(outer, "transparency", 1.0, 0.90)
    animation.tween_property(inner, "scale", Vector3(2.05, 1, 2.05), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    animation.tween_property(inner, "transparency", 1.0, 0.72)
    animation.tween_property(lamp, "light_energy", 0.0, 0.66)
    animation.finished.connect(aura.queue_free)
    return aura
