"""Apply genuinely downloaded CC0 black-marble stone PBR to real 500k D20.

Creates A/B originals:
  - "as_downloaded": actual free 1K CC0 Nero Marquina source maps.
  - "subdued_black": identical source maps with documented albedo remapping
    removing white marble streak saturation to match neutral jet-black gloss.
Neither is the BlenderKit owner-selected Procedural Obsidian (still 403).
No image generator, no blue/purple reflectance, no texture claimed as authentic obsidian.
"""
import bpy,sys,json,hashlib,struct,math
from pathlib import Path
import numpy as np
from PIL import Image
from mathutils import Vector

args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
assert len(args)==3,"Usage: repaired_500k.glb CC0_SOURCE_DIR OUTPUT_DIR"
SOURCE=Path(args[0]).resolve()
PACK=Path(args[1]).resolve()
OUT=Path(args[2]).resolve()
OUT.mkdir(parents=True,exist_ok=True)
OLD_SHA="67650874fe979f6b7b82ad0e596fd5ea8d3397c58c50fa0d5cf8e4c83c9edadf"
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==OLD_SHA
source=json.loads((PACK/"real_cc0_material_manifest.json").read_text())
assert source["material"]=="Nero Marquina black marble"
assert source["actual_PBR_channels_acquired"] and source["license"].startswith("CC0")
for channel in ("baseColor.png","normal.png","roughness.png"):
    assert (PACK/channel).is_file(),channel
    src_entry=next(a for a in source["textures"] if a["file"]==channel)
    assert hashlib.sha256((PACK/channel).read_bytes()).hexdigest()==src_entry["sha256"]

base=np.asarray(Image.open(PACK/"baseColor.png").convert("RGB"),dtype=np.float32)/255.
normal=np.asarray(Image.open(PACK/"normal.png").convert("RGB"),dtype=np.uint8)
rough=np.asarray(Image.open(PACK/"roughness.png").convert("L"),dtype=np.float32)/255.
assert base.shape==(1024,1024,3)
assert normal.shape==(1024,1024,3)
assert float(rough.mean())<.2,("Expected physical polished roughness source",float(rough.mean()))
# Derived channel is explicitly marked as ORIGINAL-CC0-SOURCED but modified.
# White marble vein brightness is not appropriate on jet-black volcanic glass:
# remap it to quiet black-charcoal detail, keeping its actual spatial structure.
luma=base.mean(axis=2)
mapped=np.where(luma<.3,.023+.014*(luma/.3),.037+.095*np.power((luma-.3)/.7,1.35))
mapped=np.clip(mapped,.021,.132)
derived_albedo=np.stack((mapped*.97,mapped,mapped*1.025),axis=2)
derived_rough=np.clip(.100+(rough-.05)*.28,.082,.19)
# Source normal image preserved unmodified, strength tuned in actual BSDF.
Image.fromarray((np.clip(derived_albedo,0,1)*255).astype(np.uint8),"RGB").save(OUT/"cc0_nero_derived_black_albedo.png")
Image.fromarray((np.clip(derived_rough,0,1)*255).astype(np.uint8),"L").save(OUT/"cc0_nero_derived_polished_roughness.png")
Image.open(PACK/"normal.png").save(OUT/"cc0_nero_original_normal.png")

def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def native_png_image(filename,name,noncolor=False):
    img=bpy.data.images.load(str(filename),check_existing=False)
    img.name=name
    if noncolor:img.colorspace_settings.name="Non-Color"
    img.pack()
    return img

def setup_stone(obj,variant):
    assert len(obj.data.materials)>=2
    if variant=="as_downloaded":
        color=PACK/"baseColor.png"
        roughness=PACK/"roughness.png"
    else:
        color=OUT/"cc0_nero_derived_black_albedo.png"
        roughness=OUT/"cc0_nero_derived_polished_roughness.png"
    normalpath=PACK/"normal.png"
    colors=[native_png_image(color,variant+"_real_source_color"),
      native_png_image(roughness,variant+"_real_source_roughness",True),
      native_png_image(normalpath,variant+"_real_source_normal",True)]
    for i in range(2):
        mat=bpy.data.materials.new("CC0Nero_"+variant+("_faces" if i==0 else "_EdgeSatin"))
        mat.use_nodes=True
        nt=mat.node_tree
        bs=nt.nodes.get("Principled BSDF")
        bs.inputs["Metallic"].default_value=0
        bs.inputs["IOR"].default_value=1.49
        bs.inputs["Roughness"].default_value=.13 if i==0 else .24
        bs.inputs["Coat Weight"].default_value=.40 if i==0 else .22
        bs.inputs["Coat Roughness"].default_value=.055 if i==0 else .13
        bc=nt.nodes.new("ShaderNodeTexImage")
        bc.label="REAL_CCO_SOURCE_ALBEDO" if variant=="as_downloaded" else "DERIVED_CC0_DARK_ALBEDO"
        bc.image=colors[0]
        nt.links.new(bc.outputs["Color"],bs.inputs["Base Color"])
        if i==0:
            rf=nt.nodes.new("ShaderNodeTexImage")
            rf.image=colors[1]
            nt.links.new(rf.outputs["Color"],bs.inputs["Roughness"])
        # Real Godot scene acceptance expects a valid PBR normal channel on
        # BOTH stone face and satin-cut-edge surfaces. Earlier draft lost the
        # normal on the bevel; that's a true material regression, not a test bug.
        norm=nt.nodes.new("ShaderNodeTexImage")
        norm.image=colors[2]
        normalmap=nt.nodes.new("ShaderNodeNormalMap")
        normalmap.inputs["Strength"].default_value=.10 if i==0 else .035
        nt.links.new(norm.outputs["Color"],normalmap.inputs["Color"])
        nt.links.new(normalmap.outputs["Normal"],bs.inputs["Normal"])
        obj.material_slots[i].material=mat

def do_geometry_uv(obj):
    assert obj.data.uv_layers.active
    # The original Blender face atlas is 5x4. Repeat one material per face
    # instead of sampling unrelated tiny, quarter-of-a-marble atlas patches.
    uv=obj.data.uv_layers.active.data
    for loop in uv:
        u,v=loop.uv
        loop.uv=(u*5%1,v*4%1)

def studio(scene):
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-1.035))
    floor=bpy.context.object
    floor.name="OnlyStudioBlackSurface"
    mat=bpy.data.materials.new("OnlyStudioMatteNeutral")
    mat.diffuse_color=(.018,.018,.020,1.)
    floor.data.materials.append(mat)
    def softbox(name,pos,energy,x,y,color):
        lamp=bpy.data.lights.new(name,"AREA")
        lamp.energy=energy
        lamp.shape="RECTANGLE"
        lamp.size=x
        lamp.size_y=y
        lamp.color=color
        ob=bpy.data.objects.new(name,lamp)
        bpy.context.collection.objects.link(ob)
        ob.location=pos
        ob.rotation_euler=(-ob.location).to_track_quat("-Z","Y").to_euler()
    softbox("LargeCoolSoftbox",(-3.5,1.2,5.0),340,2.3,5.0,(.89,.93,1.0))
    softbox("WarmThinContour",(3,-.8,3.1),210,.8,4.0,(1.0,.89,.69))
    softbox("TopFill",(0,3.4,5.6),155,3.0,1.6,(.96,.96,1.0))
    world=bpy.data.worlds.new("Low_Ambient_Real_Reflections")
    world.use_nodes=True
    world.node_tree.nodes["Background"].inputs["Color"].default_value=(.018,.023,.026,1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value=.65
    scene.world=world
    c=bpy.data.cameras.new("Camera")
    camera=bpy.data.objects.new("Camera",c)
    bpy.context.collection.objects.link(camera)
    camera.location=(3.5,-4.6,5.0)
    camera.rotation_euler=(-camera.location).to_track_quat("-Z","Y").to_euler()
    c.type="ORTHO"
    c.ortho_scale=3.0
    scene.camera=camera
    scene.render.engine="CYCLES"
    scene.cycles.device="CPU"
    scene.cycles.samples=12
    bpy.context.view_layer.cycles.use_denoising=False
    scene.render.resolution_x=760
    scene.render.resolution_y=760
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    if bpy.app.version >= (4,0,0):
        scene.view_settings.view_transform="AgX"

def inspect_glb(file,variant):
    binary=file.read_bytes()
    assert binary[:4]==b"glTF"
    n,tag=struct.unpack_from("<II",binary,12)
    assert tag==0x4e4f534a
    gltf=json.loads(binary[20:20+n])
    nodes=[n for n in gltf["nodes"] if "mesh" in n]
    parts=[]
    for n in nodes:
        t=sum(gltf["accessors"][p["indices"]]["count"]//3 for p in gltf["meshes"][n["mesh"]]["primitives"])
        parts.append((n["name"],t))
    assert len(parts)==21 and sum(t for _,t in parts)==500000,parts
    stone=[n for n in parts if n[0].startswith("D20_Engraved")]
    gold=[n for n in parts if n[0].startswith("Gold_")]
    assert len(stone)==1 and len(gold)==20
    assert stone[0][1]==220000 and sum(n[1] for n in gold)==280000
    mats=[m for m in gltf["materials"] if m.get("name","").startswith("CC0Nero_")]
    assert len(mats)==2,[m.get("name") for m in gltf["materials"]]
    face=[m for m in mats if "_faces" in m["name"]][0]
    pbr=face["pbrMetallicRoughness"]
    assert "baseColorTexture" in pbr
    assert "metallicRoughnessTexture" in pbr
    assert "normalTexture" in face
    assert pbr.get("metallicFactor",0)==0
    assert "KHR_materials_clearcoat" in face.get("extensions",{})
    return {"path":str(file),"sha256":hashlib.sha256(binary).hexdigest(),
       "file_bytes":len(binary),"glb_indexed_triangles":500000,
       "stone_triangles":220000,"gold_triangles":280000,"meshes":21,"materials":len(mats),
       "basecolor_is_from_real_cc0_source":True,
       "original_selected_blenderkit_obsidian":False,
       "variant":variant}

results={}
for variant in ("as_downloaded","subdued_black"):
    clear()
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    stone=[o for o in meshes if o.name.startswith("D20_Engraved")]
    gold=[o for o in meshes if o.name.startswith("Gold_")]
    assert len(meshes)==21 and len(stone)==1 and len(gold)==20
    do_geometry_uv(stone[0])
    setup_stone(stone[0],variant)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=stone[0]
    glb=OUT/("D20_500K_CC0_"+variant+".glb")
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",
         use_selection=True,export_yup=True)
    results[variant]=inspect_glb(glb,variant)
    studio(bpy.context.scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/("D20_500K_CC0_"+variant+".blend")))
    path=OUT/("blender_cycles_cc0_"+variant+".png")
    bpy.context.scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)
    assert path.stat().st_size>15000
    results[variant]["blender_real_png_sha256"]=hashlib.sha256(path.read_bytes()).hexdigest()
    print("PASS_REAL_BLENDER_CC0_D20",json.dumps(results[variant]),flush=True)
manifest={"source_master_sha256":OLD_SHA,
    "real_external_CC0_maps":source["textures"],
    "original_selected_BlenderKit_material_applied":False,
    "alternate_material_publisher":"ProcTexture Nero Marquina, NOT actual obsidian",
    "texture_modification_subdued_black":"neutral black mapping and real original normal/roughness; documented transformation",
    "no_purple_light":True,
    "gold_geometry_and_material_not_replaced":True,
    "blender_variants":results,
    "mobile_phone_fps":"NOT_VERIFIED"}
(OUT/"CC0_nero_genuine_500k_blender_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("PASS_GENUINE_CC0_PBR_SOURCE_IMPORTED_ON_UNIQUE_500K_GLBS",flush=True)
