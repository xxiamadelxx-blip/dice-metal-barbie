"""Actually sculpt existing 500k triangles of one engraved D20, not instances.

Controlled two-level convex microcurvature across each triangular polished
stone facet. The SAME deformation is applied to gold glyph vertices, preserving
inset alignment. The original sharp silhouette edges are preserved by zero
displacement near the face's original boundary. This is an isolated VISUAL
experiment, not a new collision mesh and not approved final D20 shape.
"""
import bpy,numpy as np,sys,json,hashlib,struct
from pathlib import Path
from mathutils import Vector

args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
assert len(args)==2,"Usage: INPUT_CC0_BLACK_500K.glb OUT_DIR"
SOURCE=Path(args[0]).resolve();ROOT=Path(args[1]).resolve()
ROOT.mkdir(parents=True,exist_ok=True)
SRC_SHA="6def24e17a3fbbf2d6e2861ae4775b61e0b6928d8170c12fdd6a48412270ef6e"
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SRC_SHA
AMPLITUDES={"micro_008":.008,"micro_022":.022}
def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
def all_meshes():
    data=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    stone=[o for o in data if o.name.startswith("D20_Engraved")]
    gold=[o for o in data if o.name.startswith("Gold_")]
    assert len(stone)==1 and len(gold)==20 and len(data)==21
    return stone[0],gold,data
def geometry_buffer(obj):
    n=len(obj.data.vertices)
    xyz=np.empty(n*3,dtype=np.float32)
    obj.data.vertices.foreach_get("co",xyz)
    return xyz.reshape((n,3))
def coord_matrices(obj):
    m=obj.matrix_world
    rotation=np.array([[m[i][j] for j in range(3)] for i in range(3)],dtype=np.float64)
    translate=np.array([m[i][3] for i in range(3)],dtype=np.float64)
    inv=np.linalg.inv(rotation)
    return rotation,translate,inv
def gold_face_directions(golds):
    directions=[]
    for ob in sorted(golds,key=lambda x:x.name):
        coords=geometry_buffer(ob)
        R,T,_=coord_matrices(ob)
        center=(coords@R.T+T).mean(axis=0)
        norm=np.linalg.norm(center)
        assert .45<norm<1.20,("Unexpected die physical dimensions",ob.name,center)
        directions.append(center/norm)
    directions=np.array(directions,dtype=np.float64)
    dots=directions@directions.T
    np.fill_diagonal(dots,-1)
    assert float(dots.max())<.97,("Face centers collided; cannot safely bend",float(dots.max()))
    return directions
def sculpt(obj,centers,amp,gold_own_center=None):
    xyz=geometry_buffer(obj).astype(np.float64)
    R,T,inv=coord_matrices(obj)
    world=xyz@R.T+T
    lengths=np.maximum(1e-7,np.linalg.norm(world,axis=1))
    if gold_own_center is not None:
        use=np.tile(gold_own_center,(len(xyz),1))
        selected_cos=np.einsum("ij,ij->i",world/lengths[:,None],use)
    else:
        angles=(world/lengths[:,None])@centers.T
        selected=np.argmax(angles,axis=1)
        use=centers[selected]
        selected_cos=np.max(angles,axis=1)
    t=np.clip((selected_cos-.805)/(.985-.805),0,1)
    w=t*t*(3-2*t)
    displacement=w*amp
    displaced=world+use*displacement[:,None]
    local=(displaced-T)@inv.T
    assert np.max(np.linalg.norm(displaced-world,axis=1)) <= amp+1.e-5
    obj.data.vertices.foreach_set("co",local.astype(np.float32).reshape(-1))
    obj.data.update()
    return {"vertex_count":int(len(xyz)),"max_displacement":round(float(displacement.max()),6),
            "mean_displacement":round(float(displacement.mean()),6),
            "intact_edge_vertices":int(np.sum(t==0))}
def glb_geometry(path):
    raw=path.read_bytes()
    j,tag=struct.unpack_from("<II",raw,12)
    assert raw[:4]==b"glTF" and tag==0x4e4f534a
    g=json.loads(raw[20:20+j])
    parts=[]
    for node in g["nodes"]:
        if "mesh" not in node: continue
        tris=sum(g["accessors"][p["indices"]]["count"]//3 for p in g["meshes"][node["mesh"]]["primitives"])
        parts.append((node["name"],tris))
    assert len(parts)==21 and sum(x[1] for x in parts)==500000
    assert sum(x[1] for x in parts if x[0].startswith("Gold_"))==280000
    assert sum(x[1] for x in parts if x[0].startswith("D20_Engraved"))==220000
    assert len([x for x in parts if x[0].startswith("Gold_")])==20
    return {"glb_sha256":hashlib.sha256(raw).hexdigest(),"file_bytes":len(raw),
            "triangles":500000,"mesh_nodes":21,"stone_triangles":220000,"gold_triangles":280000}

def studio_render(tag):
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-1.035))
    floor=bpy.context.object
    matte=bpy.data.materials.new("OnlyTemporaryBlackVelvet")
    matte.diffuse_color=(.014,.016,.018,1)
    floor.data.materials.append(matte)
    def light(name,pos,energy,size,color):
        l=bpy.data.lights.new(name,"AREA");l.energy=energy
        l.shape="RECTANGLE";l.size=size[0];l.size_y=size[1]
        l.color=color
        ob=bpy.data.objects.new(name,l)
        bpy.context.collection.objects.link(ob)
        ob.location=pos
        ob.rotation_euler=(-ob.location).to_track_quat("-Z","Y").to_euler()
    light("CoolSoftbox",(-3.5,1.2,5.0),380,(2.3,5),(.86,.9,1.0))
    light("WarmGoldRim",(3,-.8,3.1),230,(.8,4),(1,.89,.74))
    light("VerySmallTop",(0,3.4,5.6),180,(3,1.6),(.96,.97,1.0))
    world=bpy.data.worlds.new("TrueStudioDark")
    world.use_nodes=True
    world.node_tree.nodes["Background"].inputs["Color"].default_value=(.017,.02,.024,1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value=.58
    scene=bpy.context.scene;scene.world=world
    data=bpy.data.cameras.new("ReviewCamera")
    camera=bpy.data.objects.new("ReviewCamera",data)
    bpy.context.collection.objects.link(camera)
    camera.location=(3.5,-4.6,5)
    camera.rotation_euler=(-camera.location).to_track_quat("-Z","Y").to_euler()
    data.type="ORTHO";data.ortho_scale=3
    scene.camera=camera
    scene.render.engine="CYCLES";scene.cycles.device="CPU";scene.cycles.samples=10
    bpy.context.view_layer.cycles.use_denoising=False
    scene.render.resolution_x=760;scene.render.resolution_y=760
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    if bpy.app.version >= (4,0,0):
        scene.view_settings.view_transform="AgX"
    sourceblend=ROOT/("sculpted_"+tag+"_source.blend")
    bpy.ops.wm.save_as_mainfile(filepath=str(sourceblend))
    file=ROOT/("blender_cycles_sculpt_"+tag+".png")
    scene.render.filepath=str(file)
    bpy.ops.render.render(write_still=True)
    assert file.stat().st_size>25000
    return str(file)

results={}
for tag,amplitude in AMPLITUDES.items():
    clear()
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    stone,gold,meshes=all_meshes()
    centers=gold_face_directions(gold)
    info={}
    info["stone"]=sculpt(stone,centers,amplitude)
    ordered=sorted(gold,key=lambda x:x.name)
    for i,g in enumerate(ordered):
        info[g.name]=sculpt(g,centers,amplitude,gold_own_center=centers[i])
    # Imported glTF custom vertex normals may otherwise keep all ~500k
    # triangles visually flat even though their real positions are curved.
    # Clear custom split normals only on the stone, then Blender regenerates
    # actual geometric normals on export, proving that the geometry matters.
    if getattr(stone.data,"has_custom_normals",False):
        bpy.ops.object.select_all(action="DESELECT")
        stone.select_set(True)
        bpy.context.view_layer.objects.active=stone
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
        info["stone"]["old_custom_normals_cleared"]=True
    else:
        info["stone"]["old_custom_normals_cleared"]=False
    assert info["stone"]["max_displacement"]>.75*amplitude
    assert len(ordered)==20
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:obj.select_set(True)
    bpy.context.view_layer.objects.active=stone
    glb=ROOT/("D20_500K_CC0_"+tag+".glb")
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",
                              use_selection=True,export_yup=True)
    geom=glb_geometry(glb)
    render=studio_render(tag)
    results[tag]={"amplitude":amplitude,"geometry":geom,
      "stone_geometry":info["stone"],
      "gold_geometry":[info[o.name] for o in ordered],
      "cycles_png":render,
      "cycles_png_sha256":hashlib.sha256(Path(render).read_bytes()).hexdigest(),
      "source_sourced_real_CC0_material_unchanged":True}
    print("PASS_REAL_MICROCURVED_500K_GLB_BLENDER",tag,json.dumps(geom),flush=True)
record={"source_material_glb_sha256":SRC_SHA,
        "stone_source":"Actual CC0 Nero Marquina derivative, not BlenderKit obsidian",
        "visual_only_does_not_modify_collision_body":True,
        "original_engraved_gold_follows_same_deformation":True,
        "gold_separate_mesh_count":20,
        "one_die_unique_triangles":500000,
        "owner_art_approval":"NOT_VERIFIED",
        "models":results}
(ROOT/"actual_microcurvature_manifest.json").write_text(json.dumps(record,indent=2)+"\n")
print("PASS_TWO_ACTUAL_SCULPTED_500K_REAL_BLENDER_SOURCES",flush=True)
