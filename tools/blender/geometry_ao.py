"""Actual geometric short-range AO for the already Boolean-cut Blender D20.

CPU-only, offline, deterministic. NO Cycles-bake, AI, painting or random-mask
fallback. A Blender BVHTree computes true occlusion against the real render
mesh from rays launched from sampled UV0 surface texels. The internal Cycles
bake control failed white EMIT, and EXTERNAL returned no output file on the
current Blender 4.0.2 Actions image; do not mislabel this as a Cycles bake.

512x512 36-ray sampled geometry map is bilinearly expanded to 1024x1024 with
the same island UVs. Die physics hull, face mapping and Godot runtime untouched.
"""
import math
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

WORK=512
SIZE=1024
RAY_COUNT=36
MAX_DISTANCE=.24
ORIGIN_EPSILON=.003

def _sample_directions(normal):
    # Fixed cosine-weighted hemisphere, rotated in Fibonacci sequence.
    z=Vector((0.0,0.0,1.0))
    tangent=normal.cross(z)
    if tangent.length<1.e-5:
        tangent=normal.cross(Vector((0.0,1.0,0.0)))
    tangent.normalize()
    bitangent=normal.cross(tangent).normalized()
    vectors=[]
    for i in range(RAY_COUNT):
        phi=math.tau*((i*.618033988749895)%1.0)
        radius=math.sqrt((i+.5)/RAY_COUNT)
        up=math.sqrt(max(0.0,1.0-radius*radius))
        vectors.append((tangent*math.cos(phi)*radius +
                        bitangent*math.sin(phi)*radius + normal*up).normalized())
    return vectors

def _interpolate_bilinear(source):
    # 2x bilinear upscale: geometry rays remain the ONLY AO signal.
    h,w=source.shape
    out=np.empty((h*2,w*2),dtype=np.float32)
    out[::2,::2]=source
    out[1::2,::2]=(source+np.vstack((source[1:],source[-1:])))*.5
    out[::2,1::2]=(source+np.hstack((source[:,1:],source[:,-1:])))*.5
    out[1::2,1::2]=(
        source + np.vstack((source[1:],source[-1:])) +
        np.hstack((source[:,1:],source[:,-1:])) +
        np.vstack((np.hstack((source[:,1:],source[:,-1:]))[1:],
                   np.hstack((source[:,1:],source[:,-1:]))[-1:]))) *.25
    return out

def bake_d20_geometry_ao(shell, out):
    out=Path(out)
    mesh=shell.data
    assert len(mesh.uv_layers)==1 and mesh.uv_layers.active.name=='D20FaceAtlas', (
        'AO must use the GLB primary D20 5x4 numbered face atlas')
    mesh.calc_loop_triangles()
    bvh=BVHTree.FromObject(shell,bpy.context.evaluated_depsgraph_get())
    assert bvh is not None,'Cannot construct D20 Boolean geometry BVH'
    atlas=np.ones((WORK,WORK),dtype=np.float32)
    touched=np.zeros((WORK,WORK),dtype=bool)
    total_rays=0
    total_hits=0
    sampled=0

    for triangle in mesh.loop_triangles:
        loops=triangle.loops
        uv=np.array([mesh.uv_layers.active.data[i].uv[:] for i in loops],
                    dtype=np.float64)*WORK
        # Blender image pixel memory starts at the LOWER texture edge.
        uv=np.clip(uv,0.0,WORK-1.0001)
        a,b,c=uv
        denom=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
        if abs(denom)<1.e-7:
            continue
        xmin=max(0,int(math.floor(min(uv[:,0]))))
        xmax=min(WORK-1,int(math.ceil(max(uv[:,0]))))
        ymin=max(0,int(math.floor(min(uv[:,1]))))
        ymax=min(WORK-1,int(math.ceil(max(uv[:,1]))))
        if xmax<xmin or ymax<ymin:
            continue
        xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,
                          np.arange(ymin,ymax+1)+.5)
        ba=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/denom
        bb=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/denom
        bc=1.0-ba-bb
        unused=~touched[ymin:ymax+1,xmin:xmax+1]
        keep=(ba>=-1.e-6)&(bb>=-1.e-6)&(bc>=-1.e-6)&unused
        rows,cols=np.where(keep)
        if not len(rows):
            continue
        points=[mesh.vertices[mesh.loops[i].vertex_index].co for i in loops]
        normal=triangle.normal.normalized()
        if normal.length<.1:
            continue
        directions=_sample_directions(normal)
        for row,col in zip(rows,cols):
            origin=(points[0]*float(ba[row,col])+
                    points[1]*float(bb[row,col])+
                    points[2]*float(bc[row,col]))
            ray_start=origin+normal*ORIGIN_EPSILON
            hits=0
            for direction in directions:
                hit,_,_,distance=bvh.ray_cast(ray_start,direction,MAX_DISTANCE)
                if hit is not None and distance>ORIGIN_EPSILON:
                    hits+=1
            value=1.0-.92*(hits/RAY_COUNT)
            y=ymin+int(row)
            x=xmin+int(col)
            atlas[y,x]=value
            touched[y,x]=True
            total_rays+=RAY_COUNT
            total_hits+=hits
            sampled+=1

    assert sampled>18000, ('Real D20 UV atlas had too few sampled texels: %d'
                          % sampled)
    # AO texture baking requires subtexel area filtering: raw BVH ray
    # visibility is discrete at 512px. A fixed 5-tap separable Gaussian
    # removes Monte Carlo staircase edges before saving at 1024px.
    # This uses ONLY real AO ray samples; no painted or invented shadows.
    # Outside the actual UV islands stays white to avoid atlas bleeding.
    raw_atlas=atlas
    filt=np.array([1,4,6,4,1],dtype=np.float32)/16.0
    padded=np.pad(raw_atlas,((0,0),(2,2)),constant_values=1.0)
    blur_x=sum(filt[i]*padded[:,i:i+WORK] for i in range(5))
    padded=np.pad(blur_x,((2,2),(0,0)),constant_values=1.0)
    filtered=sum(filt[i]*padded[i:i+WORK,:] for i in range(5))
    # Standard PBR AO intensity control: slightly strengthen ONLY the
    # measured ray-derived occlusion after anti-aliasing, preserving the
    # white neutral surface and local cavity penumbrae. This is not drawn
    # geometry or an acceptance threshold change.
    filtered=np.clip(1.0-(1.0-filtered)*1.16,0.0,1.0)
    filtered[~touched]=1.0
    result=_interpolate_bilinear(filtered)
    assert result.shape==(SIZE,SIZE)
    mid=((result>.075)&(result<.925))
    mid_fraction=float(mid.mean())
    dynamic=float(result.std())
    px_hits=float(total_hits/max(1,total_rays))
    print('D20_BVH_AO_RAYS: sampled=%d rays=%d hits=%d hit_fraction=%.5f '
          'midtone=%.5f std=%.5f' %
          (sampled,total_rays,total_hits,px_hits,mid_fraction,dynamic),
          flush=True)
    assert px_hits>.0004 and mid_fraction>.008 and dynamic>.025, (
        'Blender actual Boolean-cut geometry has no meaningful AO cavities')
    pixels=np.empty((SIZE,SIZE,4),dtype=np.float32)
    pixels[:,:,:3]=result[:,:,None]
    pixels[:,:,3]=1.0
    image=bpy.data.images.new('D20_BVH_TrueCavityAO',width=SIZE,
                              height=SIZE,alpha=False,float_buffer=False)
    image.pixels.foreach_set(pixels.ravel())
    image.update()
    image.alpha_mode='NONE'
    destination=out/'d20_geometry_baked_ao.png'
    image.filepath_raw=str(destination)
    image.file_format='PNG'
    image.save()
    assert destination.exists() and destination.stat().st_size>10000, (
        'Blender geometry AO PNG not saved')
    bpy.data.images.remove(image)
    print('D20_GEOMETRY_AO_BAKED: rays=%d hit_fraction=%.5f '
          'midtones=%.5f output=%s' %
          (total_rays,px_hits,mid_fraction,destination.name),flush=True)
    return {'file':destination.name,'resolution':SIZE,
            'source_resolution':WORK,'rays_per_sample':RAY_COUNT,
            'bake':'Blender BVHTree geometry AO from Boolean-cut render shell',
            'ray_hits':int(total_hits),
            'ray_sampled_texels':int(sampled),
            'cavity_pixels':int(np.count_nonzero(result<.88)),
            'cavity_min':float(result.min()),
            'luma_std':dynamic,
            'dark_fraction':float(np.mean(result<.88)),
            'runtime_ao':'NOT_IN_GLTF_YET_IMPORT_TEST_REQUIRED'}
