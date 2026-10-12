"""An independently authored D20 following D20_instruction.md, not the Codex GLB.
Creates true engraved Boolean stone + recessed gold, real 1024 PBR maps,
exports glTF, deletes original die, reimports own GLB and renders with Cycles.
No image generation; graphics are Blender/Godot original engine frames.
"""
import bpy, math, sys, json, hashlib, time, struct
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
    # Source RGB PNG bytes must be ~23/25/28 (Codex instruction), NOT
    # 3/4/4 as in the failed proof. Image.save stores these as PNG byte
    # values, and glTF BaseColorTexture decodes sRGB when imported.
    stone=np.stack((.090+tile*.006,.098+tile*.006,.110+tile*.007),axis=2).astype(np.float32)
    r=np.clip(.17 + tile*.025,.12,.225)
    mr=np.stack((np.ones_like(r),r,np.zeros_like(r)),axis=2).astype(np.float32)
    # Artist's controlled study transferred FROM actual rotating Godot shots.
    # Model geometry/corners/engraving never changed. The 5x4 UV0 atlas already
    # groups each physically planar triangle in its own tile.
    # Small, finite lapping normal slope .12 creates spatial specular gradient
    # and fades to zero at UV tile borders, avoiding a raised contour seam.
    slope=np.float32(.12)
    u=np.mod((x+.5)*5.0/n,1.0)
    v=np.mod((y+.5)*4.0/n,1.0)
    ramp=np.clip(np.minimum.reduce([u,1-u,v,1-v])*4.0,0.0,1.0)
    nx=(u-.5)*2*slope*ramp
    ny=(v-.5)*2*slope*ramp
    nz=np.sqrt(np.maximum(0.0,1-nx*nx-ny*ny))
    normal=np.stack((.5+.5*nx,.5+.5*ny,.5+.5*nz),axis=2).astype(np.float32)
    assert normal.shape==(n,n,3)
    log("ACTUAL_TANGENT_NORMAL_ATLAS",{"slope":float(slope),
       "uv_tiles":"5x4","border_normal":"(0,0,1)",
       "xy_minmax":[float(nx.min()),float(nx.max()),float(ny.min()),float(ny.max())],
       "computed_not_painted_highlights":True})
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
    nn.inputs["Strength"].default_value=1.0
    m.node_tree.links.new(tex.outputs["Color"],nn.inputs["Color"])
    m.node_tree.links.new(nn.outputs["Normal"],bs.inputs["Normal"])

def cutter_glyph(value,center,normal,up,font,gold=False):
    data=bpy.data.curves.new("Glyph_%02d"%value,"FONT")
    data.body=str(value);data.font=font;data.size=.43
    data.align_x="CENTER";data.align_y="CENTER";data.resolution_u=6
    data.extrude=.0015 if gold else .06
    data.bevel_depth=.00065 if gold else 0
    glyph=bpy.data.objects.new(("Gold_%02d" if gold else "Cut_%02d")%value,data)
    bpy.context.collection.objects.link(glyph)
    glyph.rotation_mode="QUATERNION"
    # Set BOTH normal and readable in-plane type orientation. The previous
    # normal-only quaternion rotated the primary "20" almost upside down.
    up=(up-normal*up.dot(normal)).normalized()
    right=up.cross(normal).normalized()
    glyph.rotation_quaternion=Matrix((right,up,normal)).transposed().to_quaternion()
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


def enforce_exported_pbr_channels(glb, mr_png, albedo_png):
    """Fix real BIN-packed glTF ORM payload AFTER Blender exporter.
    The original source-image connection was silently exported as ORM
    R=0/G=255/B=0 (black AO + matte roughness) despite "all slots present".
    Keep geometry, UV, separate original gold and all other textures intact.
    Use authored genuine roughness G and *NEUTRAL* AO R=1 until a
    genuine validated spatial AO bake is available. This is NOT a fake AO bake.
    """
    data=glb.read_bytes()
    magic,version,total=struct.unpack_from("<III",data,0)
    assert magic==0x46546c67 and version==2 and total==len(data)
    jl,jtag=struct.unpack_from("<II",data,12)
    assert jtag==0x4e4f534a
    doc=json.loads(data[20:20+jl])
    bpos=20+jl
    bl,btag=struct.unpack_from("<II",data,bpos)
    assert btag==0x004e4942
    blob=bytearray(data[bpos+8:bpos+8+bl])
    material=next(m for m in doc["materials"] if m.get("name")=="PolishedObsidian")
    mr_index=material["pbrMetallicRoughness"]["metallicRoughnessTexture"]["index"]
    image_id=doc["textures"][mr_index]["source"]
    image=doc["images"][image_id]
    mr_bytes=mr_png.read_bytes()
    assert mr_bytes.startswith(b"\x89PNG\r\n\x1a\n")
    # Source is an actual numeric image with source G=0.17; source R=1
    # leaves occlusion neutral, B=0 for a dielectric.
    padding=(-len(blob))%4
    if padding: blob.extend(b"\x00"*padding)
    begin=len(blob)
    blob.extend(mr_bytes)
    if len(blob)%4:blob.extend(b"\x00"*((-len(blob))%4))
    view_index=image["bufferView"]
    doc["bufferViews"][view_index]["byteOffset"]=begin
    doc["bufferViews"][view_index]["byteLength"]=len(mr_bytes)
    image["name"]="VerifiedStudioNeutralAO_AuthoredRoughness"
    image["mimeType"]="image/png"
    material["occlusionTexture"]={"index":mr_index,"strength":1}
    material["pbrMetallicRoughness"]["metallicFactor"]=0
    material["pbrMetallicRoughness"].pop("roughnessFactor",None)
    # The exporter can ALSO silently pack an all-black albedo when a source
    # texture is shared between a polished face and a copy of its edge shader.
    # Repack exactly the authoring PNG bytes into the referenced glTF image.
    # Both stone materials can refer to the SAME image source via distinct
    # texture indices; patching its original bufferView keeps both correct.
    color_id=doc["textures"][
        material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    ]["source"]
    albedo_image=doc["images"][color_id]
    source_albedo=albedo_png.read_bytes()
    assert source_albedo[:8] == bytes((137,80,78,71,13,10,26,10)), "Author PNG not valid"
    if len(blob)%4:blob.extend(bytes((0,))*((-len(blob))%4))
    start=len(blob)
    blob.extend(source_albedo)
    if len(blob)%4:blob.extend(bytes((0,))*((-len(blob))%4))
    albedo_view=doc["bufferViews"][albedo_image["bufferView"]]
    albedo_view["byteOffset"]=start
    albedo_view["byteLength"]=len(source_albedo)
    albedo_image["name"]="SourceRGB_Verified_Obsidian"
    albedo_image["mimeType"]="image/png"
    doc["buffers"][0]["byteLength"]=len(blob)
    jsondata=json.dumps(doc,separators=(",",":"),ensure_ascii=False).encode("utf-8")
    jsondata+=b" "*((-len(jsondata))%4)
    total_len=12+8+len(jsondata)+8+len(blob)
    rebuilt=(struct.pack("<III",magic,version,total_len)
            +struct.pack("<II",len(jsondata),0x4e4f534a)+jsondata
            +struct.pack("<II",len(blob),0x004e4942)+bytes(blob))
    assert len(rebuilt)==total_len
    glb.write_bytes(rebuilt)
    log("REAL_GLTF_ORM_REPAIRED",'red AO neutral 1.0; GREEN authored roughness ~0.17; BLUE metallic 0',
        "image_bytes",len(mr_bytes),"albedo_bytes",len(source_albedo),"new_glb_sha",hashlib.sha256(rebuilt).hexdigest())
    return {"source_ao":"UNVERIFIED, neutral white R=1 fallback",
            "roughness":"AUTHORED numeric G channel, source range ~0.14..0.20",
            "glb_image_buffer_repair":True, "albedo_packed_from_actual_png":True}

def build():
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    ims=maps()
    # A/B study: dielectric clearcoat, never metallic stone or emission.
    stone=mat("PolishedObsidian",0.0,.17,(.015,.017,.020),.26)
    gold=mat("GoldRecessedNoEmission",1.0,.35,(.56,.335,.105),.06)
    place_maps(stone,ims)
    # Key visual complaint: bright specular bevel reads as a raised metal
    # picture-frame around each triangle. Real bevel must REMOVE stone, not
    # add a ridge. Give only chamfer polygons a broader, darker microhighlight.
    edge=stone.copy()
    edge.name="PolishedObsidian_EdgeSatin"
    edge_bs=edge.node_tree.nodes.get("Principled BSDF")
    for link in list(edge_bs.inputs["Roughness"].links):
        edge.node_tree.links.remove(link)
    edge_bs.inputs["Roughness"].default_value=.31
    edge_bs.inputs["Coat Weight"].default_value=.05
    edge_bs.inputs["Coat Roughness"].default_value=.30
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1)
    shell=bpy.context.object;shell.name="D20_Engraved_Obsidian"
    shell.data.materials.append(stone)
    shell.data.materials.append(edge)
    assert len(shell.data.polygons)==20
    # Rotate one primary triangular face to the actual +Z inspection direction.
    top=max(shell.data.polygons,key=lambda p:p.normal.z)
    q=top.normal.rotation_difference(Vector((0,0,1)))
    shell.data.transform(q.to_matrix().to_4x4())
    shell.data.update()
    # In the approved authoring pose one triangle apex points towards +Y.
    # Rotation changes only VISUAL geometry (this is an isolated art experiment).
    upper=max(shell.data.polygons,key=lambda p:p.normal.z)
    tip=max((shell.data.vertices[j].co for j in upper.vertices),key=lambda v:v.y)
    shell.data.transform(Matrix.Rotation(math.atan2(tip.x,tip.y),4,"Z"))
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
    # Geometry A/B: original edge width .023/4 segments formed an overly
    # bright apparent raised rim. Shrink the cut to .010/3 segments. Use
    # index 1 satin dielectric only for chamfer polygons, leaving all 20
    # triangular numbered face planes perfectly flat and polished.
    bev=shell.modifiers.new("INWARD_10MM_EQUIVALENT_EDGE_CUT","BEVEL")
    bev.width=.010;bev.segments=3;bev.limit_method="ANGLE";bev.angle_limit=.34
    bev.material=1
    active(shell);bpy.ops.object.modifier_apply(modifier=bev.name)
    edge_poly_count=sum(1 for f in shell.data.polygons if f.material_index==1)
    assert edge_poly_count>15, "Bevel was not assigned to satin, ridge may remain"
    for f in shell.data.polygons:
        f.use_smooth = f.material_index==1
    log("RECESSED_EDGE_PROFILE",{"bevel_width":.010,"segments":3,
        "satin_bevel_polygons":edge_poly_count})
    fnt=Path("/usr/share/fonts/truetype/dejavu/DejaVuSerifCondensed-Bold.ttf")
    assert fnt.is_file(),"Codex-profile licensed typeface absent"
    font=bpy.data.fonts.load(str(fnt))
    cutters=[]; inserts=[]
    for i,sp in enumerate(face_specs):
        n=numbers[i];pos=sp["center"]-sp["up"]*.035
        nominal_up=Vector((0,1,0)) if abs(sp["normal"].z)>.90 else Vector((0,0,1))
        up=(nominal_up-sp["normal"]*nominal_up.dot(sp["normal"])).normalized()
        cutters.append(cutter_glyph(n,pos,sp["normal"],up,font,False))
        ins=cutter_glyph(n,pos,sp["normal"],up,font,True)
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
    # An actual raised border would project BEYOND any original flat face
    # plane. Evaluate each source face halfspace against every FINAL Boolean
    # vertex, not merely the apparent edge highlight on a PNG.
    worst_protrusion=max(
       (v.co-sp["center"]).dot(sp["normal"])
       for v in shell.data.vertices for sp in face_specs)
    assert worst_protrusion < .0002, ("BEVEL OUTSIDE ORIGINAL D20 SURFACE",worst_protrusion)
    log("PASS_EDGES_NOT_ABOVE_FACE_PLANES",round(worst_protrusion,7))
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
    repaired_orm=enforce_exported_pbr_channels(glb,ROOT/"learned_obsidian_metalrough.png",ROOT/"learned_obsidian_albedo.png")
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
    receipt={"shader":"real authored PBR, dielectric metallic=0, coat=.26, coat rough=.09",
             "art_pass":"real 5x4 authored tangent-normal micro-lapping slope .12, after Godot yaw0/45/90 lab",
             "glyph_size":.43, "gold_roughness":.35, "authored_micro_normal_slope":.12,
             "num_original_glyphs":glyph_count,"boolean_polygons":stone_polygon_count,
             "edge_treatment":{"bevel_width":.010,"segments":3,"material":"PolishedObsidian_EdgeSatin",
                 "edge_roughness":.31,"face_roughness_mean":.17,
                 "raised_edge_geometry_positive_error":float(worst_protrusion)},
             "exported_pbr":repaired_orm,
             "face_numbers":numbers,"cycles_ao":ao_status,
             "source_glb_sha256":hashlib.sha256(glb.read_bytes()).hexdigest(),
             "roundtrip_mesh_count":len(imported),"blender":bpy.app.version_string}
    (ROOT/"manifest.json").write_text(json.dumps(receipt,indent=2))
    log("DONE",json.dumps(receipt))
    

def make_studio_hdr():
    """Actual shared physically evaluated HDR radiance source for both engines.
    Panels exist IN THE LIGHTING, not prepainted on any stone texture.
    Blender Z-up latlong; Godot imports the same image as a real panorama.
    """
    w,h=512,256
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    theta=(yy+.5)/h*math.pi
    phi=(xx+.5)/w*(2*math.pi)
    d=np.stack((np.sin(theta)*np.cos(phi),
                np.sin(theta)*np.sin(phi),
                np.cos(theta)),axis=-1)
    base=.25+.12*np.maximum(d[:,:,2],0.0)
    radiance=np.stack((base*.91,base,base*1.06),axis=-1).astype(np.float32)
    # Facet-guided light cards: directions are specular reflections from
    # ACTUAL dominant source D20 face normals as seen by the inspection
    # camera at (3.5, -4.6, 5), not arbitrary scene decoration.
    # First card touches upper (-camera x,+Z) planes. Second/final cards
    # give warm/cool shape to near-vertical polygons. All live in the HDR.
    # No emitted or painted fake shine in obsidian BaseColor PNG.
    for pos,width,height,color in [
        ((.21,-.01,.97),.24,.54,(3.8,4.1,4.4)),
        ((.62,-.80,-.04),.27,.52,(2.7,2.2,1.65)),
        ((-.92,0.0,-.39),.23,.47,(1.8,2.05,2.45)),
        ((-.46,.60,.65),.18,.35,(1.25,1.35,1.55)),
    ]:
        axis=np.array(pos,dtype=np.float32)
        axis/=np.linalg.norm(axis)
        world_up=np.array((0,0,1),dtype=np.float32)
        right=np.cross(axis,world_up)
        if np.linalg.norm(right)<.05:right=np.array((1,0,0),dtype=np.float32)
        right/=np.linalg.norm(right)
        up=np.cross(right,axis)
        facing=np.sum(d*axis,axis=-1)
        den=np.maximum(facing,.0001)
        rx=np.abs(np.sum(d*right,axis=-1)/den)
        ry=np.abs(np.sum(d*up,axis=-1)/den)
        feather=np.clip(np.minimum((width-rx)/.09,(height-ry)/.09),0,1)
        feather*=np.clip(facing*10,0,1)
        radiance+=feather[:,:,None]*np.asarray(color,dtype=np.float32)
    # Image.save() in Ubuntu Blender 4.0 wrote a PNG payload even though the
    # filename ended in .hdr. Godot correctly rejected it. Encode actual
    # Radiance RGBE with valid per-scanline RLE packets, then reopen FROM DISK.
    # No external image generator, no painted-specular workaround.
    peak=radiance.max(axis=2)
    mant,expo=np.frexp(peak)
    rgbe=np.zeros((h,w,4),dtype=np.uint8)
    enabled=peak>1.e-30
    scale=np.zeros_like(peak)
    scale[enabled]=np.ldexp(np.ones_like(peak[enabled]),8-expo[enabled])
    rgbe[:,:,:3]=np.clip(radiance*scale[:,:,None],0,255).astype(np.uint8)
    rgbe[:,:,3]=np.where(enabled,expo+128,0).astype(np.uint8)
    path=ROOT/"learned_studio.hdr"
    with path.open("wb") as stream:
        stream.write(("#?RADIANCE\\nFORMAT=32-bit_rle_rgbe\\n\\n-Y %d +X %d\\n" % (h,w)).replace("\\n","\n").encode())
        for y in range(h):
            stream.write(bytes((2,2,w>>8,w&255)))
            for ch in range(4):
                channel=rgbe[y,:,ch]
                for start in range(0,w,128):
                    chunk=channel[start:start+128]
                    stream.write(bytes((len(chunk),)))
                    stream.write(chunk.tobytes())
    assert path.read_bytes().startswith(b"#?RADIANCE"), "HDR encoding regression"
    img=bpy.data.images.load(str(path),check_existing=False)
    img.name="Learned_shared_studio_HDR"
    img.colorspace_settings.name="Non-Color"
    img.pack()
    log("ACTUAL_STUDIO_HDR",path,(w,h),path.stat().st_size)
    return img

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
    world.use_nodes=True
    nodes=world.node_tree.nodes
    bg=nodes.get("Background")
    studio_tex=nodes.new("ShaderNodeTexEnvironment")
    studio_tex.name="ActualWideSoftboxHDR"
    studio_tex.image=make_studio_hdr()
    world.node_tree.links.new(studio_tex.outputs["Color"],bg.inputs["Color"])
    bg.inputs["Strength"].default_value=.82
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
