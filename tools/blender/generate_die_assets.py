"""Offline Blender 4.x premium GLB experiment. VISUAL ONLY, never a Jolt hull.

Godot Y-up -> Blender Z-up -> glTF Y-up, original D20/D6 dimensions.
The generated objects use literal Boolean-cut numeral contours, not painted labels.
"""
import argparse
import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector

PHI = (1 + math.sqrt(5)) / 2
FACES = [[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
 [1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
 [3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
 [4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]]
NORMALS6 = [(0,1,0),(0,-1,0),(1,0,0),(-1,0,0),(0,0,1),(0,0,-1)]
VALUES6 = [1,6,2,5,3,4]

def vec(x):
    return Vector((float(x[0]),-float(x[2]),float(x[1])))

def model(sides):
    if sides == 20:
        raw = [(-1,PHI,0),(1,PHI,0),(-1,-PHI,0),(1,-PHI,0),
               (0,-1,PHI),(0,1,PHI),(0,-1,-PHI),(0,1,-PHI),
               (PHI,0,-1),(PHI,0,1),(-PHI,0,-1),(-PHI,0,1)]
        verts = [vec(Vector(x).normalized()*0.88) for x in raw]
        faces = FACES
        normals = []
        for f in faces:
            a,b,c = [verts[j] for j in f]
            center = (a+b+c)/3
            n = (b-a).cross(c-a).normalized()
            normals.append(n if n.dot(center)>0 else -n)
        values=[0]*20
        next_low=1
        for i in range(20):
            if values[i]: continue
            opp=next(j for j in range(20) if normals[i].dot(normals[j]) < -.999)
            values[i],values[opp]=next_low,21-next_low
            next_low+=1
        assert sorted(values)==list(range(1,21))
        return verts,faces,values
    verts=[]
    faces=[]
    for n0 in NORMALS6:
        n=vec(n0)
        u=Vector((1,0,0)) if abs(n.x)<.5 else Vector((0,1,0))
        v=n.cross(u)
        center=n*.61
        verts.extend([center-u*.61-v*.61,center+u*.61-v*.61,
                      center+u*.61+v*.61,center-u*.61+v*.61])
        k=len(faces)*4
        faces.append([k,k+1,k+2,k+3])
    # Six separately described quads must share the same 8 vertices;
    # duplicate coincident vertices leave the boolean input non-manifold.
    unique = []
    lookup = {}
    welded_faces = []
    for face in faces:
        indices = []
        for index in face:
            p = verts[index]
            key = tuple(round(float(axis), 7) for axis in p)
            if key not in lookup:
                lookup[key] = len(unique)
                unique.append(p)
            indices.append(lookup[key])
        welded_faces.append(indices)
    assert len(unique) == 8, 'D6 must be a watertight 8-vertex cube'
    return unique,welded_faces,VALUES6

def active(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj

def geometry(verts,faces,material):
    data=bpy.data.meshes.new('GemExactNumbers')
    fixed=[]
    for f in faces:
        p=[verts[i] for i in f]
        normal=(p[1]-p[0]).cross(p[2]-p[0])
        center=sum(p,Vector())/len(p)
        fixed.append(f if normal.dot(center)>0 else list(reversed(f)))
    data.from_pydata(verts,[],fixed)
    data.update()
    obj=bpy.data.objects.new('Sculpted_Obsidian',data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    return obj

def material(name,color,metallic,roughness):
    m=bpy.data.materials.new(name)
    m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Metallic'].default_value=metallic
    shader.inputs['Roughness'].default_value=roughness
    return m

def text_mesh(value,center,normal,size,depth,font,name,as_cutter=False):
    data=bpy.data.curves.new(name+'_contour','FONT')
    data.body=str(value)
    data.font=font
    data.size=size
    data.extrude=depth
    data.bevel_depth=0.0 if as_cutter else .0008
    data.resolution_u=3 if as_cutter else 8
    data.align_x='CENTER'
    data.align_y='CENTER'
    o=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(o)
    o.rotation_mode='QUATERNION'
    o.rotation_quaternion=normal.to_track_quat('Z','Y')
    o.location=center
    active(o)
    bpy.ops.object.convert(target='MESH')
    return bpy.context.view_layer.objects.active

def bevel_shell(shell,sides):
    m=shell.modifiers.new('Three_segment_physically_beveled_edges','BEVEL')
    m.width=.035 if sides==20 else .075
    m.segments=3
    m.limit_method='ANGLE'
    m.angle_limit=.35
    active(shell)
    bpy.ops.object.modifier_apply(modifier=m.name)

def unwrap(shell):
    active(shell)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.025)
    bpy.ops.object.mode_set(mode='OBJECT')

def engraved_die(sides, font):
    verts,faces,values=model(sides)
    shell=geometry(verts,faces,material('BlackObsidan_D%d'%sides,(.048,.058,.079),.19,.19))
    bevel_shell(shell,sides)
    print('PRE_CUT D%d: stone polygons=%d, verts=%d, dimensions=%s' % (
        sides,len(shell.data.polygons),len(shell.data.vertices),str(tuple(round(v,3) for v in shell.dimensions))),flush=True)
    assert len(shell.data.polygons) >= sides, 'Bevel destroyed original stone topology'
    gold=material('BronzeGold_D%d'%sides,(.87,.56,.24),.54,.27)
    # Dark studio environments make fully metallic bronze nearly invisible.
    # A controlled warm material response keeps the recessed numbers readable
    # without switching to fake floating white UI labels.
    gold_bsdf=gold.node_tree.nodes.get('Principled BSDF')
    if 'Emission Color' in gold_bsdf.inputs:
        gold_bsdf.inputs['Emission Color'].default_value=(.33,.17,.04,1.0)
        gold_bsdf.inputs['Emission Strength'].default_value=.22
    inserts=[]
    cutters=[]
    for i,f in enumerate(faces):
        p=[verts[j] for j in f]
        center=sum(p,Vector())/len(p)
        normal=(p[1]-p[0]).cross(p[2]-p[0]).normalized()
        if normal.dot(center)<0: normal=-normal
        size=(.225 if values[i]>=10 else .295) if sides==20 else .47
        cutter=text_mesh(values[i],center-normal*.006,normal,
                         size,.042,font,'BooleanDigitCut_%02d'%i,as_cutter=True)
        cutters.append(cutter)
        inset=text_mesh(values[i],center-normal*.016,normal,
                        size,.0025,font,'Bronze_Engraved_%d'%values[i])
        inset.data.materials.append(gold)
        inserts.append(inset)
    # A single Boolean through the UNION of spatially disjoint glyph cutters
    # avoids a sequence of increasingly complex, fragile n-gon operations.
    # Mesh Join transforms each digit into the active object's local space.
    active(cutters[0])
    for cutter in cutters[1:]:
        cutter.select_set(True)
    bpy.ops.object.join()
    combined=bpy.context.view_layer.objects.active
    combined.name='CombinedClosedGlyphCutters'
    print('ONE_BOOLEAN D%d: cutters=%d glyph faces=%d stone pre=%d' % (
        sides,len(cutters),len(combined.data.polygons),len(shell.data.polygons)),flush=True)
    mod=shell.modifiers.new('AllFaceGlyphs_OneExactBoolean','BOOLEAN')
    mod.operation='DIFFERENCE'
    mod.solver='EXACT'
    mod.object=combined
    active(shell)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print('ONE_BOOLEAN_RESULT D%d stone post=%d' % (
        sides,len(shell.data.polygons)),flush=True)
    assert len(shell.data.polygons)>sides*2, 'D%d Boolean erased stone' % sides
    bpy.data.objects.remove(combined,do_unlink=True)
    # This proof uses scalar PBR material inputs with no image textures.
    # UV unwrap is deferred to baked PBR art; headless smart_project() needs
    # a GUI area and must not block geometry export.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in inserts:obj.select_set(True)
    bpy.context.view_layer.objects.active=inserts[0]
    bpy.ops.object.join()
    bronze=bpy.context.view_layer.objects.active
    bronze.name='Recessed_Bronze_Number_Geometry'
    print('Booleans D%d: stone polygons=%d bronze polygons=%d' % (sides, len(shell.data.polygons), len(bronze.data.polygons)))
    assert len(shell.data.polygons) >= sides*2
    assert len(bronze.data.polygons)>sides*5
    return shell,bronze,values

def export_and_preview(sides,out,font):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    shell,gold,values=engraved_die(sides,font)
    filepath=out/('d%d_boolean_engraved.glb'%sides)
    bpy.ops.object.select_all(action='DESELECT')
    shell.select_set(True)
    gold.select_set(True)
    bpy.context.view_layer.objects.active=shell
    bpy.ops.export_scene.gltf(filepath=str(filepath),export_format='GLB',
                              use_selection=True,export_yup=True,export_apply=True)
    camera_data=bpy.data.cameras.new('OverheadInspection')
    camera=bpy.data.objects.new('OverheadInspection',camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location=(2.8,-3.2,2.5)
    camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=2.75
    bpy.context.scene.camera=camera
    for name,location,color,strength in [
        ('WarmSoftbox',(-3,-2,4),(1,.77,.56),520),
        ('CoolSoftbox',(3,2,1),(.52,.72,1),420)]:
        l=bpy.data.lights.new(name,'AREA')
        l.energy=strength
        l.color=color
        l.shape='DISK'
        l.size=3
        o=bpy.data.objects.new(name,l)
        bpy.context.collection.objects.link(o)
        o.location=location
        o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler()
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=40
    scene.cycles.device='CPU'
    # The distro Blender may be built without Intel OpenImageDenoise.
    # Disable denoising rather than letting an unrelated renderer feature
    # block GLB/PNG evidence production.
    scene.cycles.use_denoising=False
    for layer in scene.view_layers:
        layer.cycles.use_denoising=False
    scene.render.resolution_x=600
    scene.render.resolution_y=600
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.world.color=(.12,.125,.14)
    preview=out/('d%d_boolean_preview.png'%sides)
    scene.render.filepath=str(preview)
    bpy.ops.render.render(write_still=True)
    return {'faces':len(values),'numbers':values,'triangles':len(shell.data.polygons),
            'glb':filepath.name,'preview':preview.name,'glb_bytes':filepath.stat().st_size}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',default='build/premium-glb')
    argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    args=parser.parse_args(argv)
    out=Path(args.output).resolve()
    out.mkdir(parents=True,exist_ok=True)
    fp=Path('/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf')
    font=bpy.data.fonts.load(str(fp)) if fp.exists() else bpy.data.fonts.get('Bfont')
    manifest={'blender':bpy.app.version_string,
              'note':'visual-only source; Jolt hull and outcome unchanged',
              'dice':{}}
    for sides in (20,6):
        manifest['dice']['D%d'%sides]=export_and_preview(sides,out,font)
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('PASS Blender true digit Boolean engraving + GLB export, D20 and D6')

if __name__=='__main__':
    main()
