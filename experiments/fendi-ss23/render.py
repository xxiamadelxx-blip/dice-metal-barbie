"""Blender real-geometry viewport turntable, no photo plane, no fake rendering."""
import bpy, math, os, sys
from mathutils import Vector
from pathlib import Path

OUT = Path("build/fendi-ss23")
OUT.mkdir(parents=True, exist_ok=True)
GLB = OUT / "candidate.glb"
if not GLB.exists():
    raise RuntimeError("Cannot render without a real mesh")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(GLB.resolve()))
meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
if not meshes:
    raise RuntimeError("Imported GLB contains zero mesh objects")
corners=[]
for o in meshes:
    corners.extend(o.matrix_world @ Vector(p) for p in o.bound_box)
mins=Vector(tuple(min(v[i] for v in corners) for i in range(3)))
maxs=Vector(tuple(max(v[i] for v in corners) for i in range(3)))
center=(mins+maxs)*.5
size=maxs-mins
print("IMPORTED MESH",len(meshes),"bounds",tuple(size),flush=True)
if max(size)<=.00001:
    raise RuntimeError("Zero-size GLB")
root=bpy.data.objects.new("FIGURE_ROOT",None)
bpy.context.scene.collection.objects.link(root)
for o in meshes:
    o.parent=root
    o.matrix_parent_inverse=root.matrix_world.inverted()
# Raw TripoSR meshes use +X as the upright body axis (head at +X);
# turn +X to +Z without stretching and center AFTER rotation.
long_axis=max(range(3),key=lambda i: size[i])
if long_axis == 0:
    root.rotation_euler[1] = -math.pi / 2
elif long_axis == 1:
    root.rotation_euler[0] = math.pi / 2
scale = 1.65 / max(size)
root.scale = [scale] * 3
root.location = -(root.rotation_euler.to_matrix() @ center) * scale

# Photo comparison views use neutral, non-textured studio and untouched 3D mesh.
scene=bpy.context.scene
scene.render.engine="CYCLES"
scene.cycles.samples=24
# Ubuntu distro Blender is compiled without Intel OpenImageDenoise.
# Force raw sample output instead of failing at the denoising stage.
scene.cycles.use_denoising=False
bpy.context.view_layer.cycles.use_denoising=False
scene.render.resolution_x=900
scene.render.resolution_y=1350
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.film_transparent=False
world=bpy.data.worlds.new("White studio")
scene.world=world
world.use_nodes=True
world.node_tree.nodes.get("Background").inputs["Color"].default_value=(.82,.82,.82,1)
world.node_tree.nodes.get("Background").inputs["Strength"].default_value=.8

def make_area(name,loc,power,size):
    bpy.ops.object.light_add(type="AREA", location=loc)
    ob=bpy.context.object
    ob.name=name
    ob.data.energy=power
    ob.data.shape="DISK"
    ob.data.size=size
    direction=Vector((0,0,0))-ob.location
    ob.rotation_euler=direction.to_track_quat("-Z","Y").to_euler()
make_area("Key softbox",(-3,-4,5),450,5)
make_area("Fill softbox",(4,-2,3),300,4)
make_area("Rim softbox",(0,4,4),600,3)

bpy.ops.object.camera_add()
camera=bpy.context.object
scene.camera=camera
camera.data.type="ORTHO"
camera.data.ortho_scale=2.15
camera.data.lens=60
for i,position in enumerate([(0,-3.4,1.15),(2.4,-2.4,1.1),(3.4,0,1.1),(0,3.4,1.1)]):
    camera.location=position
    camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str((OUT / ("angle_%02d.png"%i)).resolve())
    bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str((OUT / "candidate_working.blend").resolve()))
print("BLENDER REAL MESH RENDERS COMPLETED",flush=True)
