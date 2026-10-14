"""Isolated REAL Blender/Cycles A/B preview of user-selected Blendkit obsidian.

Imports the already-authored, Boolean-engraved D20 GLB; applies the third-party
procedural node material to stone faces ONLY. Gold and satin cut bevel remain.
No raw third-party .blend is published; this is NOT a Godot/mobile acceptance.
"""
import bpy
import hashlib
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

def cli():
    args = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    if len(args) != 3:
        raise SystemExit("Usage: blender -b -P preview_blendkit_on_d20.py -- MATERIAL.blend DIE.glb OUT_DIR")
    material, die, out = map(Path,args)
    for file in (material,die):
        assert file.is_file() and file.stat().st_size>1000, file
    out.mkdir(parents=True,exist_ok=True)
    return material,die,out

def add_light(name, pos, power, size, color):
    lamp=bpy.data.lights.new(name,"AREA")
    lamp.energy=power
    lamp.shape="RECTANGLE"
    lamp.size=size[0]
    lamp.size_y=size[1]
    lamp.color=color
    ob=bpy.data.objects.new(name,lamp)
    bpy.context.collection.objects.link(ob)
    ob.location=pos
    ob.rotation_euler=(-ob.location).to_track_quat("-Z","Y").to_euler()

def render_view(scene,camera,out,position,name):
    camera.location=position
    camera.rotation_euler=(-camera.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str(out/name)
    bpy.ops.render.render(write_still=True)
    assert (out/name).stat().st_size>10000
    print("REAL_BLENDKIT_D20_CYCLES_RENDER",out/name,flush=True)

def main():
    blend,die,out=cli()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    with bpy.data.libraries.load(str(blend),link=False) as (source,dest):
        matches=[name for name in source.materials if "obsidian" in name.lower()]
        if len(matches)!=1:
            raise ValueError("Expected exactly one named obsidian material in selected asset; got "+repr(matches))
        dest.materials=[matches[0]]
    material=dest.materials[0]
    assert material is not None and material.use_nodes
    material.name="BLENDKIT_REFERENCE_ProceduralObsidian"
    bpy.ops.import_scene.gltf(filepath=str(die))
    stone=[o for o in bpy.context.scene.objects
           if o.type=="MESH" and o.name.startswith("D20_Engraved")]
    assert len(stone)==1,[(o.name,o.type) for o in bpy.context.scene.objects]
    shell=stone[0]
    faces=0;bevels=0
    for slot in shell.material_slots:
        current=slot.material
        assert current is not None
        if "EdgeSatin" in current.name:
            bevels+=1
        elif "PolishedObsidian" in current.name:
            faces+=1
            slot.material=material
        else:
            raise AssertionError("Unknown stone surface: "+current.name)
    assert faces==1 and bevels>=1, ("Face/edge primitive audit",faces,bevels)
    gold=[o for o in bpy.context.scene.objects if o.type=="MESH" and o.name.startswith("Gold_")]
    assert len(gold)==20,len(gold)
    assert all(o.data.materials and o.data.materials[0] is not material for o in gold)
    # Same finite lights as previous independent studio: light sources
    # create specular reflections, NEVER pre-painted on the stone pixels.
    bpy.ops.mesh.primitive_plane_add(size=100,location=(0,0,-1.015))
    floor=bpy.context.object
    floor.name="Studio_Comparison_Surface"
    fabric=bpy.data.materials.new("DarkComparisonMatte")
    fabric.diffuse_color=(.05,.075,.067,1)
    floor.data.materials.append(fabric)
    for spec in (
        ("CoolLargeSoftbox",(-3.4,1.4,4.8),420,(2.8,5),(.82,.90,1.0)),
        ("WarmNarrowSoftbox",(3,-.6,3),260,(1.0,4.5),(1.0,.83,.62)),
        ("TopSoftbox",(0,3.3,5.5),180,(3.0,2.0),(1.0,.95,.86)),
    ):
        add_light(*spec)
    world=bpy.data.worlds.new("NeutralLowFill")
    world.use_nodes=True
    world.node_tree.nodes["Background"].inputs["Color"].default_value=(.075,.085,.095,1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value=.6
    scene=bpy.context.scene
    scene.world=world
    scene.render.engine="CYCLES"
    scene.cycles.device="CPU"
    scene.cycles.samples=32
    scene.render.resolution_x=1000
    scene.render.resolution_y=850
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.view_settings.view_transform="AgX"
    camera_data=bpy.data.cameras.new("ReviewCamera")
    camera=bpy.data.objects.new("ReviewCamera",camera_data)
    bpy.context.collection.objects.link(camera)
    camera_data.type="ORTHO"
    camera_data.ortho_scale=3
    scene.camera=camera
    render_view(scene,camera,out,(3.5,-4.6,5.0),"blendkit_obsidian_d20_oblique.png")
    render_view(scene,camera,out,(0,0,7.0),"blendkit_obsidian_d20_overhead.png")
    n=material.node_tree.nodes
    audit={"status":"BLENDER_CYCLES_REAL_RENDER_ONLY",
           "source_material":"Blendkit Procedural Obsidian / diaverx miky",
           "blend_sha256":hashlib.sha256(blend.read_bytes()).hexdigest(),
           "unchanged_die_glb_sha256":hashlib.sha256(die.read_bytes()).hexdigest(),
           "faces_replaced":faces, "bevel_surfaces_unchanged":bevels,
           "gold_meshes_unchanged":len(gold), "node_count":len(n),
           "renderer":bpy.app.version_string+" Cycles CPU",
           "godot_glb_material_bake":"NOT_VERIFIED",
           "jolt_physics_modified":False}
    (out/"preview_manifest.json").write_text(json.dumps(audit,indent=2)+"\n")
    print("PASS_REAL_CYCLES_SELECTED_OBSIDIAN_D20",json.dumps(audit),flush=True)

if __name__=="__main__":
    main()
