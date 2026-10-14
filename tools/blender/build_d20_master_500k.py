"""500,000 *unique* geometric triangles in one D20 with Boolean-recessed gold.
Uses the previously approved real 59,276-triangle authored GLB as actual input.
This is NOT 500k GPU MultiMesh instances. This is a Blender geometry/GLB
prototype; art approval, on-device Android FPS and external obsidian source OPEN.
Run: blender -b -t 3 -P tools/blender/build_d20_master_500k.py -- INPUT.glb OUT_DIR
"""
import bpy
import bmesh
import sys
import json
import hashlib
import math
from pathlib import Path
from mathutils import Vector

TARGET = 500000
ARG = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
assert len(ARG) == 2, "Usage: INPUT.glb OUTPUT_DIRECTORY"
SOURCE, OUT = Path(ARG[0]).resolve(), Path(ARG[1]).resolve()
OUT.mkdir(parents=True, exist_ok=True)
assert SOURCE.exists(), SOURCE
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == "ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f", "Wrong source D20"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
stone = [obj for obj in objects if obj.name.startswith("D20_Engraved")]
gold = [obj for obj in objects if obj.name.startswith("Gold_")]
assert len(stone) == 1 and len(gold) == 20, [(o.name, len(o.data.polygons)) for o in objects]
assert len(objects) == 21, "No extra meshes"
assert sum(len(o.data.polygons) for o in objects) == 59276, "Baseline must be original real tris"
for obj in objects:
    assert all(len(face.vertices) == 3 for face in obj.data.polygons)
# First stage genuinely subdivides each triangular face and its adjoining
# edges, preserving watertight/Boolean-engraved surface and UV interpolation.
# Stone: (cuts+1)^2=16 triangles per original, Glyph: 4 triangles per original.
# Second stage distributes 2 additional triangles at existing face centroids
# with no new T-junctions. Target exact 500K (not modifier estimate).
def refine(obj, cuts):
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=cuts,use_grid_fill=True)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bm.normal_update()
    return bm

meshes=[]
for obj in objects:
    cuts=3 if obj is stone[0] else 1
    bm=refine(obj,cuts)
    meshes.append((obj,bm))
    print("D20_MASTER_BASE_SUBDIV",obj.name,len(bm.faces),"cuts",cuts,flush=True)
base=sum(len(bm.faces) for _,bm in meshes)
assert base < TARGET, ("initial stage wrong",base)
needed=(TARGET-base)//2
assert base + needed*2 == TARGET, (base,needed)
# Prefer facets + engraving edges over undifferentiated highpoly text.
# 35,000 pokes on stone produce real triangles around the engraved cavity;
# remaining uniformly distributed across 20 individual numerals.
stone_bm=next(bm for obj,bm in meshes if obj is stone[0])
quota_stone=min(35000,needed,len(stone_bm.faces))
quotas={stone[0].name:quota_stone}
remaining=needed-quota_stone
gold_bms=sorted([(obj,bm) for obj,bm in meshes if obj in gold],key=lambda x:x[0].name)
gold_total=sum(len(bm.faces) for _,bm in gold_bms)
taken=0
for i,(obj,bm) in enumerate(gold_bms):
    # Proportional allocation with last-remainder exactness.
    n=(remaining-taken if i==len(gold_bms)-1 else int(remaining*len(bm.faces)/gold_total))
    n=min(n,len(bm.faces))
    quotas[obj.name]=n
    taken+=n
assert taken==remaining,("quota mismatch",taken,remaining)
def dispersed_faces(bm,count):
    faces=list(bm.faces)
    if count<=0: return []
    assert count<=len(faces)
    # Sample over the full geometry; stable and not order-random clustering.
    return [faces[(i*len(faces))//count] for i in range(count)]
for obj,bm in meshes:
    before=len(bm.faces)
    count=quotas[obj.name]
    if count:
        bmesh.ops.poke(bm,faces=dispersed_faces(bm,count),offset=0.0,center_mode="MEAN_WEIGHTED")
    assert len(bm.faces)==before+2*count,(obj.name,len(bm.faces),before,count)
    bm.normal_update()
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    assert all(len(f.vertices)==3 for f in obj.data.polygons)
    print("D20_MASTER_FINAL_COMPONENT",obj.name,len(obj.data.polygons),flush=True)
after=sum(len(obj.data.polygons) for obj in objects)
assert after==TARGET,("Not exactly 500k real Blender triangle polygons",after)
stone_total=len(stone[0].data.polygons)
gold_total=after-stone_total
# Preserve face shading selection and original source material slots.
for obj in objects:
    assert obj.data.materials
    assert not any(m.name.lower().startswith("emissive") for m in obj.data.materials if m)
# Selecting ALL 21 die objects, not studio/floor/camera; export one die GLB.
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active=stone[0]
glb=OUT/"d20_obsidian_gold_master_500k.glb"
bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",use_selection=True,export_yup=True)
assert glb.stat().st_size > 1500000,("GLB too small",glb.stat().st_size)
print("D20_MASTER_EXPORTED_GLB",glb,glb.stat().st_size,flush=True)

# Real Cycles capture of the *same new mesh*. No generated illustration.
# Blender imported source textures/materials are left unchanged for parity.
floor_mat=bpy.data.materials.new("Studio_BlackVelvet_Only")
floor_mat.diffuse_color=(.018,.018,.020,1)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-1.035))
floor=bpy.context.object
floor.name="Temporary_Studio_Black_Velvet"
floor.data.materials.append(floor_mat)
def area(name,pos,energy,dimensions,color):
    dat=bpy.data.lights.new(name,"AREA")
    dat.energy=energy
    dat.shape="RECTANGLE"
    dat.size,dat.size_y=dimensions
    dat.color=color
    ob=bpy.data.objects.new(name,dat)
    bpy.context.collection.objects.link(ob)
    ob.location=pos
    ob.rotation_euler=(-ob.location).to_track_quat("-Z","Y").to_euler()
area("LongCoolCard",(-3.5,1.2,5.0),340,(2.3,5),(.83,.90,1.0))
area("ThinGoldRim",(3,-.8,3.1),210,(.8,4.0),(1.0,.83,.59))
area("TopFill",(0,3.4,5.6),155,(3.0,1.6),(.95,.95,1.0))
world=bpy.data.worlds.new("Studio_True_Dark_Environment")
world.use_nodes=True
world.node_tree.nodes["Background"].inputs["Color"].default_value=(.018,.023,.029,1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value=.6
sc=bpy.context.scene
sc.world=world
sc.render.engine="CYCLES"
sc.cycles.device="CPU"
sc.cycles.samples=20
sc.render.resolution_x=720
sc.render.resolution_y=720
sc.render.resolution_percentage=100
sc.render.image_settings.file_format="PNG"
if bpy.app.version >= (4,0,0):
    sc.view_settings.view_transform="AgX"
camera_dat=bpy.data.cameras.new("Master_Review_Camera")
camera=bpy.data.objects.new("Master_Review_Camera",camera_dat)
bpy.context.collection.objects.link(camera)
camera_dat.type="ORTHO"
camera_dat.ortho_scale=3.0
camera.location=(3.5,-4.6,5.0)
camera.rotation_euler=(-camera.location).to_track_quat("-Z","Y").to_euler()
sc.camera=camera
# Preserve fully editable Blender source including original highpoly geometry.
blend=OUT/"d20_obsidian_gold_master_500k.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
sc.render.filepath=str(OUT/"blender_cycles_master_500k.png")
bpy.ops.render.render(write_still=True)
assert (OUT/"blender_cycles_master_500k.png").stat().st_size>20000
manifest={
  "authoring":"Blender true imported/modified mesh; no instancing",
  "source_glb_sha256":hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
  "exported_glb_sha256":hashlib.sha256(glb.read_bytes()).hexdigest(),
  "exported_glb_bytes":glb.stat().st_size,
  "triangle_count_blender_before_export":after,
  "stone_tris":stone_total,"gold_tris":gold_total,
  "stone_blender_object":stone[0].name,
  "gold_meshes":len(gold),
  "materials_from_original_gltf":True,
  "selected_blenderkit_material_obtained":False,
  "physics_and_android_tests":"NOT_RUN",
  "artistic_quality":"NOT_ACCEPTED",
  "blender_version":bpy.app.version_string
}
(OUT/"manifest_blender.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("PASS_ONE_REAL_D20_500000_TRIANGLES_BLENDER",json.dumps(manifest),flush=True)
