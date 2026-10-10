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
import numpy as np
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
    if sides == 4:
        # Exact tetrahedral Godot vertices; printed value = apex index + 1.
        raw=[(1,1,1),(-1,-1,1),(-1,1,-1),(1,-1,-1)]
        points=[vec(Vector(x).normalized()*.98) for x in raw]
        faces=[[j for j in range(4) if j!=opposite] for opposite in range(4)]
        return points,faces,[1,2,3,4]
    if sides == 8:
        # Exact index/number contract of src/core/octahedron.gd.
        godot_verts=[(.93,0,0),(-.93,0,0),(0,.93,0),(0,-.93,0),
                     (0,0,.93),(0,0,-.93)]
        octa_verts=[vec(p) for p in godot_verts]
        octa_faces=[[1 if i&4 else 0,3 if i&2 else 2,5 if i&1 else 4]
                    for i in range(8)]
        # Opposite face i XOR 7 sums to 9.
        return octa_verts,octa_faces,list(range(1,9))
    if sides == 12:
        # Verified Dodecahedron Godot source: dual of canonical icosahedron.
        primal_verts,primal_faces,_=model(20)
        dodeca_verts=[sum((primal_verts[j] for j in face),Vector()).normalized()*.98
                       for face in primal_faces]
        dodeca_faces=[]
        for vertex_id,normal in enumerate(primal_verts):
            outward=normal.normalized()
            ref=Vector((0,0,1)) if abs(outward.z)<.95 else Vector((1,0,0))
            tangent_x=outward.cross(ref).normalized()
            tangent_y=outward.cross(tangent_x)
            adjacent=[fi for fi,indices in enumerate(primal_faces) if vertex_id in indices]
            assert len(adjacent)==5, 'D12 requires five faces at each primal vertex'
            adjacent.sort(key=lambda fi:math.atan2(dodeca_verts[fi].dot(tangent_y),
                                                    dodeca_verts[fi].dot(tangent_x)))
            dodeca_faces.append(adjacent)
        values=[0]*12
        nxt=1
        for i,normal in enumerate(primal_verts):
            if values[i]:
                continue
            opposite=next(j for j,n in enumerate(primal_verts)
                          if normal.normalized().dot(n.normalized())<-.999)
            values[i],values[opposite]=nxt,13-nxt
            nxt+=1
        assert values==[1,2,11,12,3,4,9,10,5,6,7,8]
        return dodeca_verts,dodeca_faces,values
    assert sides == 6, 'Unsupported Blender dice shape'
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

# UV maps and image-based PBR maps are deliberately generated offline. This
# uses only numeric noise, no copyrighted photos and no network dependency.
# A low-frequency, seam-safe texture is less prone to glTF moire than the old
# high-frequency trig shader. It supplements rather than fakes engraved geometry.
def tile_noise(rng, dim, cells):
    grid = rng.random((cells, cells)).astype(np.float32)
    grid = np.pad(grid, ((0, 1), (0, 1)), mode='wrap')
    positions = np.linspace(0, cells, dim, endpoint=False, dtype=np.float32)
    i0 = np.floor(positions).astype(np.int32)
    blend = positions-i0
    blend = blend*blend*(3.0-2.0*blend)
    ax = (grid[i0[:, None], i0[None, :]] * (1.0-blend[:, None])
         + grid[i0[:, None]+1, i0[None, :]] * blend[:, None])
    bx = (grid[i0[:, None], i0[None, :]+1] * (1.0-blend[:, None])
         + grid[i0[:, None]+1, i0[None, :]+1] * blend[:, None])
    return ax * (1.0-blend[None, :]) + bx * blend[None, :]

def write_pbr_image(out, name, rgb):
    dim = rgb.shape[0]
    assert rgb.shape == (dim,dim,3)
    rgba=np.concatenate((np.clip(rgb,0.0,1.0),np.ones((dim,dim,1),dtype=np.float32)),axis=2)
    image=bpy.data.images.new(name,width=dim,height=dim,alpha=True)
    image.filepath_raw=str(out/(name+'.png'))
    image.file_format='PNG'
    # Blender's pixels use bottom-left origin, which is fine for seamless
    # textures, as long as each channel is generated with the same convention.
    image.pixels.foreach_set(rgba.astype(np.float32).ravel())
    image.save()
    image.pack()
    return image

def texture_set(out):
    dim=256
    rng=np.random.default_rng(210626)
    low=tile_noise(rng,dim,7)-0.5
    mid=tile_noise(rng,dim,24)-0.5
    fine=tile_noise(rng,dim,64)-0.5
    grain=np.clip(0.50+0.34*low+0.13*mid+0.045*fine,0.0,1.0)
    # glTF/Blender image texture *replaces* BSDF Base Color.
    # This MUST already be charcoal; a white grayscale swatch creates a pale
    # stone despite the default Principled shader previously being dark.
    # Values are linear in Blender's image pixels; exported PNG is sRGB.
    luminance=np.clip(0.138+0.041*(grain-.5),0.112,0.165)
    albedo=np.stack((luminance*.78,luminance*.88,luminance),axis=2)
    # glTF roughness is read from the G channel (linear Non-Color image).
    roughness=np.clip(0.33+0.11*low+0.035*mid,0.26,0.42)
    rough=np.stack((np.ones_like(roughness),roughness,np.zeros_like(roughness)),axis=2)
    # Smooth tangent-space micro relief with deliberately small slopes.
    height=0.69*low+0.23*mid+0.08*fine
    gx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*.20
    gy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*.20
    normal=np.stack((np.clip(.5-gx,.43,.57),np.clip(.5-gy,.43,.57),
                     np.sqrt(np.maximum(.7,1.0-(gx*2)**2-(gy*2)**2))),axis=2)
    return {'albedo':write_pbr_image(out,'obsidian_albedo',albedo),
            'roughness':write_pbr_image(out,'obsidian_roughness',rough),
            'normal':write_pbr_image(out,'obsidian_normal',normal)}

def stone_uv(mesh):
    uv=mesh.uv_layers.new(name='StoneUV')
    # Angular UV projection on the 3D stone; no headless UI operator or
    # mesh changes. Every exported stone primitive gets TEXCOORD_0.
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            vertex=mesh.vertices[mesh.loops[loop_index].vertex_index].co
            length=max(vertex.length,1.0e-8)
            u=(math.atan2(vertex.y,vertex.x)+math.pi)/(2.0*math.pi)
            v=math.acos(max(-1.0,min(1.0,vertex.z/length)))/math.pi
            uv.data[loop_index].uv=(u,v)
    return uv

def apply_stone_maps(shell, maps):
    stone_uv(shell.data)
    stone=shell.data.materials[0]
    nodes=stone.node_tree.nodes
    links=stone.node_tree.links
    bsdf=nodes.get('Principled BSDF')
    for name,image in maps.items():
        tex=nodes.new('ShaderNodeTexImage')
        tex.name='PBR_Stone_'+name
        tex.label='Offline procedural '+name
        tex.image=image
        tex.interpolation='Linear'
        tex.extension='REPEAT'
        if name == 'albedo':
            links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
        elif name == 'roughness':
            image.colorspace_settings.name='Non-Color'
            links.new(tex.outputs['Color'],bsdf.inputs['Roughness'])
        elif name == 'normal':
            image.colorspace_settings.name='Non-Color'
            bump=nodes.new('ShaderNodeNormalMap')
            bump.inputs['Strength'].default_value=.28
            links.new(tex.outputs['Color'],bump.inputs['Color'])
            links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])

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
    glyph=bpy.context.view_layer.objects.active
    if int(value) in (6,9):
        # A physical 6 upside down reads 9. Mark both with a short bar
        # underneath, exactly as on real tabletop dice, so rotation cannot
        # change the player's perceived value. Same mark is subtracted from
        # the stone and filled with metal by the existing Boolean pipeline.
        half_w=size*.21
        y_center=-size*.43
        half_h=size*.020
        half_d=depth
        verts=[(x,y,z) for z in (-half_d,half_d)
                         for y in (y_center-half_h,y_center+half_h)
                         for x in (-half_w,half_w)]
        faces=[(0,1,3,2),(4,6,7,5),(0,4,5,1),
               (2,3,7,6),(0,2,6,4),(1,5,7,3)]
        mesh=bpy.data.meshes.new(name+'_SixNineUnderbarMesh')
        mesh.from_pydata(verts,[],faces)
        mesh.update()
        bar=bpy.data.objects.new(name+'_SixNineUnderbar',mesh)
        bpy.context.collection.objects.link(bar)
        bar.rotation_mode='QUATERNION'
        bar.rotation_quaternion=normal.to_track_quat('Z','Y')
        bar.location=center
        # Join only into original glyph, leaving the world/local coordinate
        # transform of existing engraving, stone and physics unchanged.
        active(glyph)
        bar.select_set(True)
        bpy.ops.object.join()
        glyph=bpy.context.view_layer.objects.active
    return glyph

def bevel_shell(shell,sides):
    m=shell.modifiers.new('Three_segment_physically_beveled_edges','BEVEL')
    m.width={20:.035,6:.075,8:.042,12:.035,4:.032}[sides]
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

def engraved_die(sides, font, maps):
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
    placements=[]
    for i,f in enumerate(faces):
        p=[verts[j] for j in f]
        center=sum(p,Vector())/len(p)
        normal=(p[1]-p[0]).cross(p[2]-p[0]).normalized()
        if normal.dot(center)<0: normal=-normal
        if sides==4:
            # D4 cannot be marked as "one numeral per face": the winning
            # upper vertex is printed on each of its 3 adjacent faces.
            # Copy src/core/tetrahedron.gd::printed_position exactly.
            for apex in f:
                position=verts[apex].lerp(center,.48)
                placements.append((apex+1,position,normal,.31,
                                   '%02d_Apex%d'%(i,apex+1)))
        else:
            if sides==20:
                size=.225 if values[i]>=10 else .295
            elif sides==6:
                size=.47
            elif sides==8:
                size=.25
            else:
                size=.21 if values[i]>=10 else .275
            placements.append((values[i],center,normal,size,'%02d'%i))
    assert len(placements)==(12 if sides==4 else sides)
    for number,position,normal,size,uid in placements:
        cutter=text_mesh(number,position-normal*.006,normal,
                         size,.042,font,'BooleanDigitCut_'+uid,as_cutter=True)
        cutters.append(cutter)
        # Near-flush bronze (top stays below the original stone plane):
        # a 0.016-deep inlay disappeared on oblique D4 faces in real renders.
        inset=text_mesh(number,position-normal*.0035,normal,
                        size,.0025,font,'Bronze_Engraved_%d'%number)
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
    apply_stone_maps(shell,maps)
    return shell,bronze,values

def export_and_preview(sides,out,font,maps):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    shell,gold,values=engraved_die(sides,font,maps)
    # MeshLab receives the same final Boolean-cut shell via OBJ for actual
    # geometry inspection. It is only a QA candidate, never a Jolt hull.
    # MeshLab 2020's old OBJ importer asserts even on triangulated Boolean
    # results. Transfer QA-only triangles as PLY: explicit vertex/face counts,
    # no OBJ heuristics. The authored glTF and Jolt hull are NEVER changed.
    qa_file=out/('d%d_stone_qa.ply'%sides)
    shell.data.calc_loop_triangles()
    with qa_file.open('w') as fh:
        fh.write('ply\nformat ascii 1.0\ncomment Blender cut stone, QA only\n')
        fh.write('element vertex %d\n'%len(shell.data.vertices))
        fh.write('property float x\nproperty float y\nproperty float z\n')
        fh.write('element face %d\n'%len(shell.data.loop_triangles))
        fh.write('property list uchar int vertex_indices\nend_header\n')
        for v in shell.data.vertices:
            fh.write('%.8f %.8f %.8f\n'%tuple(v.co))
        for tri in shell.data.loop_triangles:
            fh.write('3 %d %d %d\n'%tuple(tri.vertices))
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
    return {'faces':len(values),'numbers':values,'engraved_glyphs':12 if sides==4 else sides,
            'underbar_numbers':[v for v in values if v in (6,9)],
            'triangles':len(shell.data.polygons),
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
    # D4 apex glyphs are tiny under a strict overhead Android camera.
    # A heavier typeface plus larger curves yield real cut strokes, not a
    # screen-space outline that breaks visual/physics consistency.
    heavy=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
    # A silent fallback would return to illegible thin apex numerals while
    # still passing model compilation. Fail the art build if the font is absent.
    if not heavy.exists():
        raise FileNotFoundError('D4 source requires DejaVuSans-Bold.ttf (fonts-dejavu-core)')
    apex_font=bpy.data.fonts.load(str(heavy))
    maps=texture_set(out)
    manifest={'blender':bpy.app.version_string,
              'note':'visual-only source; Jolt hull and outcome unchanged',
              'pbr':{'size':256,'images':[im.filepath_raw.split('/')[-1] for im in maps.values()],
                     'albedo_linear_mean':float(np.mean(np.asarray(maps['albedo'].pixels[:]).reshape((256,256,4))[:,:,:3])),
                     'description':'Deterministic offline generated PBR maps, not Cycles geometric bake'},
              'dice':{}}
    for sides in (20,6,8,12,4):
        used_font=apex_font if sides==4 else font
        manifest['dice']['D%d'%sides]=export_and_preview(sides,out,used_font,maps)
        if sides==4:
            manifest['dice']['D4']['typeface']=used_font.name
            manifest['dice']['D4']['glyph_size']=.31
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('PASS Blender true digit Boolean engraving + GLB export, D20 D6 D8 D12 D4')

if __name__=='__main__':
    main()
