"""Blender-only visual candidate: move existing gold into shallower recesses."""
import hashlib
import json
from pathlib import Path

import bpy
from mathutils import Vector

project = Path(__file__).resolve().parent
source = project / "d20_obsidian_gold.glb"
expected = "c5d971370fae51328461cbd220293d9445a14d7fd6f182b623f52551dbb8fa27"
assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
assert len(meshes) == 23
before = {obj.name: (len(obj.data.vertices), len(obj.data.polygons)) for obj in meshes}
moved = []
offset = 0.023
for obj in meshes:
    if not obj.name.startswith("Gold_"):
        continue
    coordinates = [vertex.co for vertex in obj.data.vertices]
    spans = [max(co[axis] for co in coordinates) - min(co[axis] for co in coordinates) for axis in range(3)]
    thin_axis = min(range(3), key=lambda axis: spans[axis])
    assert spans[thin_axis] < 0.005, "Gold plate thickness differs from original"
    local_normal = Vector((0.0, 0.0, 0.0))
    local_normal[thin_axis] = 1.0
    normal = (obj.matrix_world.to_3x3().inverted().transposed() @ local_normal).normalized()
    world_center = obj.matrix_world.translation
    if normal.dot(world_center) < 0:
        normal.negate()
    matrix = obj.matrix_world.copy()
    matrix.translation += normal * offset
    obj.matrix_world = matrix
    moved.append({"name": obj.name, "world_normal": list(normal), "outward_offset_model_units": offset})
assert len(moved) == 22
assert before == {obj.name: (len(obj.data.vertices), len(obj.data.polygons)) for obj in meshes}, "Geometry topology changed"
bpy.ops.file.pack_all()
authored = project / "authored"
authored.mkdir(exist_ok=True)
(authored / ".gdignore").touch()
blend = authored / "d20_inlay_refined.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
target = project / "d20_inlay_refined.glb"
bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", export_apply=False, export_cameras=False, export_lights=False)
manifest = {
    "scope": "Visual-only isolated candidate; never attached to production Jolt bodies",
    "original_file": source.name,
    "original_sha256": expected,
    "candidate_file": target.name,
    "candidate_sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
    "blend_file": str(blend.relative_to(project)),
    "blend_sha256": hashlib.sha256(blend.read_bytes()).hexdigest(),
    "blender_version": bpy.app.version_string,
    "change": "22 existing gold meshes moved outward by 0.023 model units, keeping approximately 0.00685-unit front recess; original body and local mesh topology preserved",
    "mesh_count": len(meshes),
    "topology_before_and_after": before,
    "moved_meshes": moved,
    "runtime_and_physics_changes": "NONE",
    "artistic_acceptance": "OPEN_PENDING_REAL_GODOT_CAPTURE"
}
(project / "candidate-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
print("BLENDER_TRUE_GLB_EXPORT_DONE", json.dumps({"mesh_count": len(meshes), "gold_moved": len(moved), "sha256": manifest["candidate_sha256"]}))
