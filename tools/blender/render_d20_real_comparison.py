"""Render the same source GLB as Godot with real Blender/Cycles. NO image generation.
Independent from the procedural die asset generator; no physics or model edits.
Usage: blender -b --python tools/blender/render_d20_real_comparison.py -- --glb build/premium-glb/d20_boolean_engraved.glb --out build/d20-compare/blender_cycles.png
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
parser = argparse.ArgumentParser()
parser.add_argument("--glb", required=True)
parser.add_argument("--out", required=True)
cfg = parser.parse_args(args)
source = Path(cfg.glb).resolve()
destination = Path(cfg.out).resolve()
assert source.is_file(), source
destination.parent.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
rendered_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
assert len(rendered_meshes) >= 2, "Expected original stone and inset 3D numerals"
print("COMPARE_BLENDER_ORIGINAL_GLB_SHA256:", hashlib.sha256(source.read_bytes()).hexdigest(), flush=True)

# Equivalent physical placement to the Godot compare scene. Blender Z is up.
bpy.ops.mesh.primitive_plane_add(size=200, location=(0.0, 0.0, -0.97))
table = bpy.context.object
table.name = "ComparisonFloor_NonColliding"
floor_mat = bpy.data.materials.new("MutedGreenRoughFelt_Comparison")
floor_mat.diffuse_color = (0.080, 0.162, 0.137, 1.0)
floor_mat.use_nodes = True
floor_bsdf = floor_mat.node_tree.nodes.get("Principled BSDF")
floor_bsdf.inputs["Base Color"].default_value = (0.080, 0.162, 0.137, 1.0)
floor_bsdf.inputs["Roughness"].default_value = 0.94
table.data.materials.append(floor_mat)

camera_data = bpy.data.cameras.new("MatchGodotCamera")
camera = bpy.data.objects.new("MatchGodotCamera", camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (2.8, -3.2, 2.5)
camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 3.15
bpy.context.scene.camera = camera

for name, location, color, strength in [
    ("WarmArea_Blend", (-3, -2, 4), (1.0, 0.77, 0.56), 520),
    ("CoolArea_Blend", (3, 2, 1), (0.52, 0.72, 1.0), 420),
]:
    data = bpy.data.lights.new(name, "AREA")
    data.energy = strength
    data.color = color
    data.shape = "DISK"
    data.size = 3
    light = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (-light.location).to_track_quat("-Z", "Y").to_euler()

world = bpy.data.worlds.new("StudioAmbient_Comparison")
bpy.context.scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs["Color"].default_value = (0.10, 0.13, 0.14, 1.0)
bg.inputs["Strength"].default_value = 0.6

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.device = "CPU"
scene.cycles.use_denoising = False
scene.render.resolution_x = 768
scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(destination)
scene.render.film_transparent = False
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast" if "Medium High Contrast" in [i.identifier for i in bpy.types.ColorManagedViewSettings.bl_rna.properties["look"].enum_items] else "Medium High Contrast"
# Look must be recorded: do not pretend Cycles and Godot have identical tonemappers.
bpy.ops.render.render(write_still=True)
assert destination.is_file() and destination.stat().st_size > 10000
print("PASS ACTUAL BLENDER CYCLES FRAME:", destination, destination.stat().st_size, flush=True)
