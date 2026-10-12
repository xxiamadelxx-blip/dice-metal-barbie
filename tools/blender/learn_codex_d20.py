"""An independently authored D20 following D20_instruction.md, not the Codex GLB.
Creates true engraved Boolean stone + recessed gold, real 1024 PBR maps,
exports glTF, deletes original die, reimports own GLB and renders with Cycles.
No image generation; graphics are Blender/Godot original engine frames.
"""
import bpy, math, sys, json, hashlib, time
from pathlib import Path
import numpy as np
from mathutils import Vector, Matrix, Quaternion

ROOT=Path("build/learned-d20").resolve()
ROOT.mkdir(parents=True,exist_ok=True)
def log(*args): print("LEARNED_D20",*args,flush=True)
def active(o):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active=o

def image_file(name, rgb, noncolor=False):
    n=rgb.shape[0]
    rgba=np.ones((n,n,4),dtype=np.float32)
    rgba[:,:,:3]=np.clip(rgb,0,1)
    im=bpy.data.images.new(name,width=n,height=n,alpha=True)
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw=str(ROOT/(name+".png"))
    im.file_format="PNG"
    im.save()
    if noncolor: im.colorspace_settings.name="Non-Color"
    im.pack()
    return im

def maps():
    n=1024
    rng=np.random.default_rng(20261012)
    # Subtle fields: not specular painted into albedo, no fake brushed stone.
    y,x=np.mgrid[:n,:n].astype(np.float32)
    tile=(np.sin(x*.016+np.cos(y*.011)) * .42
         + np.sin(y*.012+np.sin(x*.008))*.30
         + np.sin((x+y)*.035)*.13
         + rng.normal(0,.08,(n,n)).astype(np.float32))
    stone=np.stack((.012+tile*.002,.014+tile*.002,.017+tile*.0025),axis=2).astype(np.float32)
    r=np.clip(.17 + tile*.025,.12,.225)
    mr=np.stack((np.ones_like(r),r,np.zeros_like(r)),axis=2).astype(np.float32)
    # Real tangent-space Normal Map (OpenGL +Y), gentle polished microscopic relief.
    hx=np.roll(tile,-1,axis=1)-np.roll(tile,1,axis=1)
    hy=np.roll(tile,-1,axis=0)-np.roll(tile,1,axis=0)
    nx=np.clip(-hx*.015,-.14,.14);ny=np.clip(-hy*.015,-.14,.14)
    nz=np.sqrt(np.maximum(.92,1-nx*nx-ny*ny))
    normal=np.stack((.5+.5*nx,.5+.5*ny,.5+.5*nz),axis=2).astype(np.float32)
    return (image_file("learned_obsidian_albedo",stone),
            image_file("learned_obsidian_metalrough",mr,True),
            image_file("learned_obsidian_normal",normal,True))

def mat(name,metallic,roughness,base,coat=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value=(*base,1)
    bs.inputs["Metallic"].default_value=metallic
    bs.inputs["Roughness"].default_value=roughness
    bs.inputs["Coat Weight"].default_value=coat
    bs.inputs["Coat Roughness"].default_value=.09 if name=="PolishedObsidian" else .25
    bs.inputs["IOR"].default_value=1.49
    return m

def place_maps(m, ims):
    bs=m.node_tree.nodes.get("Principled BSDF")
    for name,im,socket in [("Base",ims[0],"Base Color"),("MetalRough",ims[1],"Roughness")]:
        t=m.node_tree.nodes.new("ShaderNodeTexImage");t.name=name;t.image=im
        m.node_tree.links.new(t.outputs["Color"],bs.inputs[socket])
    tex=m.node_tree.nodes.new("ShaderNodeTexImage");tex.name="TangentNormal";tex.image=ims[2]
    nn=m.node_tree.nodes.new("ShaderNodeNormalMap")
    nn.inputs["Strength"].default_value=.12
    m.node_tree.links.new(tex.outputs["Color"],nn.inputs["Color"])
    m.node_tree.links.new(nn.outputs["Normal"],bs.inputs["Normal"])

def cutter_glyph(value,center,normal,font,gold=False):
    data=bpy.data.curves.new("Glyph_%02d"%value,"FONT")
    data.body=str(value);data.font=font;data.size=.50
    data.align_x="CENTER";data.align_y="CENTER";data.resolution_u=6
    data.extrude=.0015 if gold else .06
    data.bevel_depth=.00065 if gold else 0
    glyph=bpy.data.objects.new(("Gold_%02d" if gold else "Cut_%02d")%value,data)
    bpy.context.collection.objects.link(glyph)
    glyph.rotation_mode="QUATERNION"
    glyph.rotation_quaternion=normal.to_track_quat("Z","Y")
    glyph.location=center-normal*(.032 if gold else .008)
    active(glyph)
    bpy.ops.object.convert(target="MESH")
    return bpy.context.view_layer.objects.active

def face_uv(mesh,face_specs):
    while mesh.uv_layers:mesh.uv_layers.remove(mesh.uv_layers[0])
    uv=mesh.uv_layers.new(name="D20_planar_5x4")
    uv.active_render=True
    mesh.uv_layers.active=uv
    count=[0]*20
    for poly in mesh.polygons:
        # Nearest face plane and normal, robust on Boolean glyph sidewalls.
        p=poly.center
        fi=min(range(20),key=lambda i:abs((p-face_specs[i]["center"]).dot(face_specs[i]["normal"]))+
               .09*(1.0-max(-1.,min(1.,poly.normal.dot(face_specs[i]["normal"])))) )
        count[fi]+=1
        f=face_specs[fi];row=fi//5;col=fi%5
        for li in poly.loop_indices:
            v=mesh.vertices[mesh.loops[li].vertex_index].co
            u=max(-.42,min(.42,(v-f["center"]).dot(f["right"])/1.50))
            t=max(-.42,min(.42,(v-f["center"]).dot(f["up"])/1.50))
            uv.data[li].uv=((col+.5+u)/5.,(row+.5+t)/4.)
    assert min(count)>0
    log("UV0 5x4 face tiles polys",count)

def build():
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    ims=maps()
    stone=mat("PolishedObsidian",0.0,.17,(.015,.017,.020),.20)
    gold=mat("GoldRecessedNoEmission",1.0,.29,(.56,.335,.105),.06)
    place_maps(stone,ims)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1)
    shell=bpy.context.object;shell.name="D20_Engraved_Obsidian";shell.data.materials.append(stone)
    assert len(shell.data.polygons)==20
    # Rotate one primary triangular face to the actual +Z inspection direction.
    top=max(shell.data.polygons,key=lambda p:p.normal.z)
    q=top.normal.rotation_difference(Vector((0,0,1)))
    shell.data.transform(q.to_matrix().to_4x4())
    shell.data.update()
    face_specs=[]
    normals=[]
    for i,p in enumerate(shell.data.polygons):
        v=[shell.data.vertices[j].co.copy() for j in p.vertices]
        c=sum(v,Vector())/3
        n=(v[1]-v[0]).cross(v[2]-v[0]).normalized()
        if n.dot(c)<0:n=-n
        right=(v[1]-v[0]).normalized()
        up=n.cross(right).normalized()
        face_specs.append({"center":c,"normal":n,"right":right,"up":up})
        normals.append(n)
    top=max(range(20),key=lambda i:normals[i].z)
    numbers=[0]*20;numbers[top]=20
    bottom=min(range(20),key=lambda i:normals[i].dot(normals[top]));numbers[bottom]=1
    unused=iter(range(2,11))
    for i in range(20):
        if numbers[i]:continue
        v=next(unused)
        j=min((k for k in range(20) if k!=i),key=lambda k:normals[k].dot(normals[i]))
        assert numbers[j]==0
        numbers[i]=v;numbers[j]=21-v
        # consume v's opposite only once
        # iterator values may be unused; ensure distinct set at the end
    assert sorted(numbers)==list(range(1,21)),numbers
    # 0.023 polished four-segment bevel, not smoothed triangular faces.
    bev=shell.modifiers.new("Physical_edge_polish","BEVEL")
    bev.width=.023;bev.segments=4;bev.limit_method="ANGLE";bev.angle_limit=.34
    active(shell);bpy.ops.object.modifier_apply(modifier=bev.name)
    for f in shell.data.polygons:f.use_smooth=False
    fnt=Path("/usr/share/fonts/truetype/dejavu/DejaVuSerifCondensed-Bold.ttf")
    assert fnt.is_file(),"Codex-profile licensed typeface absent"
    font=bpy.data.fonts.load(str(fnt))
    cutters=[]; inserts=[]
    for i,sp in enumerate(face_specs):
        n=numbers[i];pos=sp["center"]-sp["up"]*.035
        cutters.append(cutter_glyph(n,pos,sp["normal"],font,False))
        ins=cutter_glyph(n,pos,sp["normal"],font,True)
        ins.data.materials.append(gold);inserts.append(ins)
    # Single Exact Boolean on real text cutter meshes.
    active(cutters[0])
    for o in cutters[1:]:o.select_set(True)
    bpy.ops.object.join()
    union=bpy.context.view_layer.objects.active
    mod=shell.modifiers.new("ActualDeepNumeralRecesses","BOOLEAN")
    mod.operation="DIFFERENCE";mod.solver="EXACT";mod.object=union
    active(shell);bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(union,do_unlink=True)
    assert len(shell.data.polygons)>100
    face_uv(shell.data,face_specs)
    # True AO through Cycles on active image node, non-fatal but honestly audited.
    ao=bpy.data.images.new("Learned_Actual_Cycles_AO",width=1024,height=1024,alpha=False)
    ao.colorspace_settings.name="Non-Color"
    act=stone.node_tree.nodes.new("ShaderNodeTexImage");act.image=ao;act.name="ActualCyclesAO"
    stone.node_tree.nodes.active=act
    scene=bpy.context.scene
    scene.render.engine="CYCLES";scene.cycles.samples=16;scene.cycles.device="CPU"
    scene.render.bake.margin=12;scene.render.bake.use_clear=True
    active(shell)
    ao_status="not_attempted"
    try:
        bpy.ops.object.bake(type="AO")
        ao.filepath_raw=str(ROOT/"cycles_true_ao.png");ao.file_format="PNG";ao.save()
        raw=np.array(ao.pixels[:],dtype=np.float32)
        ao_status="made" if float(raw.max()-raw.min())>.08 else "uninformative"
        if ao_status=="made":
            # Supported exporter glTF material output hook (if Blender version supports it).
            group=bpy.data.node_groups.new("glTF Material Output","ShaderNodeTree")
            group.interface.new_socket(name="Occlusion",in_out="INPUT",socket_type="NodeSocketFloat")
            gn=stone.node_tree.nodes.new("ShaderNodeGroup");gn.node_tree=group
            stone.node_tree.links.new(act.outputs["Color"],gn.inputs["Occlusion"])
        log("CYCLES_AO",ao_status,float(raw.min()),float(raw.max()))
    except Exception as e:
        ao_status="FAILED:"+str(e)
        log("CYCLES_AO",ao_status)
    # Geometric inlays are separate real GLB meshes, nothing screen-space.
    stone_polygon_count=len(shell.data.polygons)
    glyph_count=len(inserts)
    authored=[shell]+inserts
    active(shell)
    for o in inserts:o.select_set(True)
    glb=ROOT/"learned_d20.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",use_selection=True,export_yup=True)
    log("GLB_EXPORT",glb,glb.stat().st_size)
    # Scene both for user's .blend and independent round-trip rendering.
    add_studio()
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"authored.blend"))
    for o in authored:bpy.data.objects.remove(o,do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=str(glb))
    imported=[o for o in bpy.context.scene.objects if o.type=="MESH" and o.name!="ComparisonFloor"]
    assert len(imported)>=2,["glb import missing",len(imported)]
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"roundtrip_import.blend"))
    scene.render.filepath=str(ROOT/"blender_cycles.png")
    bpy.ops.render.render(write_still=True)
    log("BLENDER_SOURCE_GLTF_ROUNDTRIP_RENDER",ROOT/"blender_cycles.png")
    receipt={"shader":"real authored PBR, dielectric metallic=0, coat=.20, coat rough=.09",
             "num_original_glyphs":glyph_count,"boolean_polygons":stone_polygon_count,
             "face_numbers":numbers,"cycles_ao":ao_status,
             "source_glb_sha256":hashlib.sha256(glb.read_bytes()).hexdigest(),
             "roundtrip_mesh_count":len(imported),"blender":bpy.app.version_string}
    (ROOT/"manifest.json").write_text(json.dumps(receipt,indent=2))
    log("DONE",json.dumps(receipt))
    
def add_studio():
    scene=bpy.context.scene
    floor_height=-1.015
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,floor_height))
    floor=bpy.context.object;floor.name="ComparisonFloor"
    fabric=mat("MutedGreenCloth",0.0,.92,(.085,.14,.12))
    floor.data.materials.append(fabric)
    cam=bpy.data.cameras.new("InspectionCamera")
    o=bpy.data.objects.new("InspectionCamera",cam);bpy.context.collection.objects.link(o)
    o.location=(3.5,-4.6,5)
    o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat("-Z","Y").to_euler()
    cam.type="ORTHO";cam.ortho_scale=3.0;scene.camera=o
    for name,where,power,size,col in [
        ("BlueLargeSoftbox",(-3.4,1.4,4.8),420,(2.8,5.0),(.82,.90,1)),
        ("GoldRimSoftbox",(3,-.6,3),260,(1.0,4.5),(1,.83,.62)),
        ("OverheadSoftbox",(0,3.3,5.5),180,(3.0,2.0),(1,.95,.86))
    ]:
        data=bpy.data.lights.new(name,"AREA");data.energy=power
        data.shape="RECTANGLE";data.size=size[0];data.size_y=size[1];data.color=col
        light=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(light)
        light.location=where
        light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat("-Z","Y").to_euler()
    world=bpy.data.worlds.new("StudioWorld") if bpy.data.worlds.get("StudioWorld")==None else bpy.data.worlds["StudioWorld"]
    world.use_nodes=True;world.node_tree.nodes["Background"].inputs["Color"].default_value=(.20,.23,.26,1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value=.7
    scene.world=world
    scene.render.engine="CYCLES";scene.cycles.samples=64;scene.cycles.device="CPU"
    # Debian Blender Cycles has no OpenImageDenoise: documented Codex failure.
    scene.cycles.use_denoising=False
    bpy.context.view_layer.cycles.use_denoising=False
    scene.render.resolution_x=1000;scene.render.resolution_y=850;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.view_settings.view_transform="AgX"
    scene.view_settings.look="AgX - Medium High Contrast"
    scene.view_settings.exposure=.6
    scene.camera.data.lens=50

if __name__=="__main__":
    build()
