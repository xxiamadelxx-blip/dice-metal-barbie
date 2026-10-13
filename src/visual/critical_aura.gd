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
    var color := Color(1.0, 0.70, 0.22, 0.43) if result == 20 else Color(1.0, 0.18, 0.25, 0.42)

    for index in range(2):
        var ring := MeshInstance3D.new()
        ring.name = "GoldPulse" if result == 20 else "CrimsonPulse"
        var torus := TorusMesh.new()
        torus.inner_radius = 0.735 if index == 0 else 0.67
        torus.outer_radius = 0.762 if index == 0 else 0.693
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
        ring.scale = Vector3(0.62, 1, 0.62) if index == 0 else Vector3(0.53, 1, 0.53)
        ring.position.y = 0.03 * index
        aura.add_child(ring)

    var lamp := OmniLight3D.new()
    lamp.name = "DieOriginFlash"
    lamp.light_color = Color(color.r, color.g, color.b)
    lamp.omni_range = 3.0
    lamp.light_energy = 1.15 if result == 20 else 0.95
    lamp.shadow_enabled = false
    aura.add_child(lamp)

    # A pair of expanding toroidal fronts reads as an aura emerging from
    # the stone, without particles/texture fetches on the offline Android GPU.
    var animation := aura.create_tween()
    animation.set_parallel(true)
    var rings := aura.get_children()
    var outer := rings[0] as MeshInstance3D
    var inner := rings[1] as MeshInstance3D
    animation.tween_property(outer, "scale", Vector3(1.70, 1, 1.70), 0.90).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    animation.tween_property(outer, "transparency", 1.0, 0.90)
    animation.tween_property(inner, "scale", Vector3(1.41, 1, 1.41), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    animation.tween_property(inner, "transparency", 1.0, 0.72)
    animation.tween_property(lamp, "light_energy", 0.0, 0.66)
    # Alpha 4 inspiration, but generated entirely in real die-local 3D:
    # nat20 sends fine gold sparks upward; nat1 drives dim embers out along
    # the felt. All are non-colliding, bounded and offline. No result forcing.
    var success := result == 20
    var count := 8 if success else 6
    for i in range(count):
        var angle := TAU * float(i) / float(count)
        var direction := Vector3(cos(angle),0.0,sin(angle))
        var spark := MeshInstance3D.new()
        spark.name = "GoldSpark_%d" % i if success else "CrimsonEmber_%d" % i
        var gem := SphereMesh.new()
        gem.radius = 0.036 if success else 0.049
        gem.height = 0.12 if success else 0.07
        gem.radial_segments = 8
        gem.rings = 4
        spark.mesh = gem
        var spark_material := StandardMaterial3D.new()
        spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        spark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        spark_material.albedo_color = Color(color.r,color.g,color.b,0.86)
        spark_material.emission_enabled = true
        spark_material.emission = Color(color.r,color.g,color.b)
        spark_material.emission_energy_multiplier = 1.45 if success else 0.95
        spark.material_override = spark_material
        spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        spark.position = direction * 0.30
        spark.position.y = 0.05 if success else -0.015
        aura.add_child(spark)
        var destination := direction * (0.97 if success else 0.81)
        destination.y = 0.44 if success else -0.06
        animation.tween_property(spark,"position",destination,0.72 if success else 0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        animation.tween_property(spark,"transparency",1.0,0.78)
    animation.finished.connect(aura.queue_free)
    return aura
