"""Re-author a private selected D20 in Blender; reuse its exact numeral solids and PBR.

blender -b --python this.py -- --source private.glb --output private-candidate-dir
No physical bodies, outcome code or copyrighted binary data are written to git.
"""
import argparse
import hashlib
import json
import math
import re
import struct
import sys
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Vector

FACES = [[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
         [1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
         [3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
         [4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]]
SOURCE_SHA = '4c04c1707e1ed0d59f5bee286525059d85cdec5668c2ce5969d968d3a18221df'

def canonical():
    phi = (1 + math.sqrt(5)) / 2
    v = np.array([[-1,phi,0],[1,phi,0],[-1,-phi,0],[1,-phi,0],
                  [0,-1,phi],[0,1,phi],[0,-1,-phi],[0,1,-phi],
                  [phi,0,-1],[phi,0,1],[-phi,0,-1],[-phi,0,1]],dtype=float)
    v *= .88 / np.linalg.norm(v[0])
    normals=[]
    for f in FACES:
        n=np.cross(v[f[1]]-v[f[0]],v[f[2]]-v[f[0]])
        normals.append(n/np.linalg.norm(n))
    normals=np.array(normals)
    numbers=[0]*20; low=1
    for i in range(20):
        if numbers[i]:continue
        opposite=int(np.argmin(normals @ normals[i]))
        assert np.dot(normals[i],normals[opposite]) < -.999
        numbers[i]=low;numbers[opposite]=21-low;low+=1
    return v,normals,numbers

def uv_templates(source,v,normals):
    data=source.read_bytes();length=struct.unpack_from('<I',data,12)[0]
    gltf=json.loads(data[20:20+length]);binary=data[28+length:]
    def read(index,components):
        a=gltf['accessors'][index];view=gltf['bufferViews'][a['bufferView']]
        assert a['componentType']==5126
        return np.frombuffer(binary,dtype='<f4',count=a['count']*components,
                             offset=view.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,components)
    positions=[];uvs=[];source_normals=[]
    for p in gltf['meshes'][0]['primitives']:
        positions.append(read(p['attributes']['POSITION'],3))
        uvs.append(read(p['attributes']['TEXCOORD_0'],2))
        source_normals.append(read(p['attributes']['NORMAL'],3))
    positions=np.concatenate(positions);uvs=np.concatenate(uvs)
    source_normals=np.concatenate(source_normals)
    matrices=[];errors=[]
    for face in range(20):
        n=normals[face];plane=np.dot(v[FACES[face][0]],n)
        mask=(np.abs(positions @ n-plane)<.0002)&(source_normals @ n>.999)
        assert mask.sum()>=3, ('Missing source face UV',face,int(mask.sum()))
        x=(v[FACES[face][1]]-v[FACES[face][0]])
        x/=np.linalg.norm(x);y=np.cross(n,x)
        a=np.column_stack([positions[mask] @ x,positions[mask] @ y,np.ones(mask.sum())])
        assert np.linalg.matrix_rank(a)==3,('Collinear source UV samples',face)
        m=np.linalg.lstsq(a,uvs[mask],rcond=None)[0]
        error=float(np.abs(a @ m-uvs[mask]).max())
        assert error<.0001,('Source UV seam ambiguity',face,error)
        matrices.append((x,y,m));errors.append(error)
    return matrices,errors

def active(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True);bpy.context.view_layer.objects.active=obj

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--bevel',type=float,default=.024)
    parser.add_argument('--inlay-depth',type=float,default=.013)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    assert hashlib.sha256(args.source.read_bytes()).hexdigest()==SOURCE_SHA
    args.output.mkdir(parents=True,exist_ok=True)
    v,normals,numbers=canonical()
    templates,uv_errors=uv_templates(args.source,v,normals)
    # Blender is Z-up, Godot/glTF is Y-up. This is a proper rigid rotation.
    to_blender=lambda p:Vector((float(p[0]),float(-p[2]),float(p[1])))
    to_godot=lambda p:np.array([p.x,p.z,-p.y],dtype=float)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(args.source),merge_vertices=True)
    stone=next(o for o in bpy.data.objects if o.name.startswith('Canonical_D20'))
    original_material=stone.data.materials[0]
    glyphs=sorted([o for o in bpy.data.objects if o.type=='MESH' and re.match(r'Gold_\d+',o.name)],key=lambda o:o.name)
    assert len(glyphs)==20
    # Keep source materials and complete numeral contours, including 6/9 bars.
    glyph_receipts=[];cutters=[]
    for glyph in glyphs:
        value=int(re.match(r'Gold_(\d+)',glyph.name).group(1))
        world=[glyph.matrix_world @ vert.co for vert in glyph.data.vertices]
        positions=np.array([to_godot(p)for p in world])
        face=int(np.argmax(normals @ positions.mean(axis=0)))
        assert numbers[face]==value,('Source numeral mismatch',value,face,numbers[face])
        n=to_blender(normals[face]);plane=float(v[FACES[face][0]] @ normals[face])
        heights=np.array([p.dot(n)for p in world]);h0,h1=float(heights.min()),float(heights.max())
        assert h1-h0>.00001,('Numeral not a solid',value,h0,h1)
        cutter=glyph.copy();cutter.data=glyph.data.copy();bpy.context.collection.objects.link(cutter)
        # Reuse the authored contour. Stretch only axially through the face.
        cutter.matrix_world.identity()
        for vert,p in zip(cutter.data.vertices,world):
            t=(p.dot(n)-h0)/(h1-h0)
            vert.co=p+n*((plane-.045+t*.075)-p.dot(n))
        cutters.append(cutter)
        shift=plane-args.inlay_depth-h1
        glyph.location+=n*shift
        glyph_receipts.append({'value':value,'face':face,'old_min':h0,'old_max':h1,
                               'new_top':plane-args.inlay_depth,'depth':args.inlay_depth})
    bpy.data.objects.remove(stone,do_unlink=True)
    mesh=bpy.data.meshes.new('Authored_Rounded_Cut_Obsidian')
    mesh.from_pydata([to_blender(p)for p in v],[],FACES);mesh.update()
    shell=bpy.data.objects.new('Canonical_D20_Engraved_Obsidian',mesh)
    bpy.context.collection.objects.link(shell);mesh.materials.append(original_material)
    active(shell)
    bevel=shell.modifiers.new('Rounded_outer_edges_before_true_engraving','BEVEL')
    bevel.width=args.bevel;bevel.segments=5;bevel.limit_method='ANGLE'
    bevel.angle_limit=math.radians(30);bevel.harden_normals=True
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    # One exact Boolean, through the union of spatially disjoint glyph solids.
    active(cutters[0])
    for cutter in cutters[1:]:cutter.select_set(True)
    bpy.ops.object.join();combined=bpy.context.object
    active(shell)
    cut=shell.modifiers.new('Twenty_real_numeral_recesses','BOOLEAN')
    cut.operation='DIFFERENCE';cut.solver='EXACT';cut.object=combined
    bpy.ops.object.modifier_apply(modifier=cut.name)
    bpy.data.objects.remove(combined,do_unlink=True)
    # Small physical rims let light distinguish the cavities from flat paint.
    rim=shell.modifiers.new('Fine_engraving_rims','BEVEL')
    rim.width=.0018;rim.segments=2;rim.limit_method='ANGLE'
    rim.angle_limit=math.radians(35);rim.harden_normals=True
    bpy.ops.object.modifier_apply(modifier=rim.name)
    mesh=shell.data
    uv=mesh.uv_layers.new(name='Original_Selected_Face_UV')
    for polygon in mesh.polygons:
        center=to_godot(polygon.center)
        face=int(np.argmax(normals @ center))
        x,y,m=templates[face]
        for loop_index in polygon.loop_indices:
            p=to_godot(mesh.vertices[mesh.loops[loop_index].vertex_index].co)
            q=np.array([p @ x,p @ y,1.]) @ m
            # Imported Blender UV V is opposite glTF's texture coordinates.
            uv.data[loop_index].uv=(float(q[0]),float(1-q[1]))
        polygon.use_smooth=True
    mesh.use_auto_smooth=True;mesh.auto_smooth_angle=math.radians(30)
    normal=shell.modifiers.new('Stable_flat_faces_and_smooth_bevels','WEIGHTED_NORMAL')
    normal.keep_sharp=True;normal.weight=50
    bpy.ops.object.modifier_apply(modifier=normal.name)
    bm=bmesh.new();bm.from_mesh(mesh)
    manifold=all(e.is_manifold for e in bm.edges)
    boundary=sum(not e.is_manifold for e in bm.edges);bm.free()
    assert manifold,('Non-manifold authored shell',boundary)
    all_positions=np.array([to_godot(shell.matrix_world @ p.co)for p in mesh.vertices])
    planes=np.array([v[f[0]] @ normals[i]for i,f in enumerate(FACES)])
    outside=float(np.max(all_positions @ normals.T-planes))
    assert outside<.00001,('Art escaped canonical collider',outside)
    bpy.ops.object.select_all(action='DESELECT')
    shell.select_set(True)
    for glyph in glyphs:glyph.select_set(True)
    bpy.context.view_layer.objects.active=shell
    path=args.output/'candidate-rounded-obsidian.glb'
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
                              export_apply=True,export_texcoords=True,export_normals=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/'candidate-rounded-obsidian.blend'))
    triangles=sum(len(o.data.loop_triangles)for o in [shell]+glyphs)
    # Force triangle-cache calculation for an honest export budget receipt.
    for o in [shell]+glyphs:o.data.calc_loop_triangles()
    triangles=sum(len(o.data.loop_triangles)for o in [shell]+glyphs)
    receipt={'blender':bpy.app.version_string,'source_sha256':SOURCE_SHA,
             'candidate_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
             'source_materials_reused':True,'source_gold_contours_reused':True,
             'outer_bevel':args.bevel,'inlay_depth':args.inlay_depth,
             'boolean':'Blender EXACT,20 reused numeral solids','triangles':triangles,
             'stone_manifold':manifold,'nonmanifold_edges':boundary,
             'max_outside_canonical_hull':outside,'uv_fit_error_max':max(uv_errors),
             'numerals':glyph_receipts,'physics_changes':False,'artistic_acceptance':'NOT_VERIFIED'}
    (args.output/'authoring-receipt.json').write_text(json.dumps(receipt,indent=2))
    print('AUTHORED_CANDIDATE',json.dumps(receipt),flush=True)

if __name__=='__main__':main()
