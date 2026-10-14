#!/usr/bin/env python3
"""Source-only real spherical circular studio diffuser for Godot Mobile.

Generates image-based lighting as radiometrically encoded linear RGBE panorama;
this file does not contain or alter BlenderKit source texture/normal/roughness.
Avoids rectangular super-Gaussian light cards used in earlier M5 experiments.
"""
from __future__ import annotations
import argparse, hashlib, json, math
from pathlib import Path
import numpy as np


def rgbe_image(rgb: np.ndarray):
    peak=np.max(rgb,axis=2)
    mantissa,expo=np.frexp(peak)
    multiplier=np.zeros_like(peak,dtype=np.float32)
    mask=peak>1e-12
    multiplier[mask]=np.ldexp(np.ones_like(peak[mask]),8-expo[mask])
    pixels=np.zeros((*rgb.shape[:2],4),np.uint8)
    pixels[:,:,:3]=np.clip(np.floor(rgb*multiplier[:,:,None]+.5),0,255).astype(np.uint8)
    pixels[:,:,3]=np.where(mask,expo+128,0).astype(np.uint8)
    return pixels


def write_hdr(path: Path, rgb: np.ndarray):
    h,w=rgb.shape[:2]
    with path.open('wb') as f:
        f.write(f'#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y {h} +X {w}\n'.encode('ascii'))
        f.write(rgbe_image(rgb).tobytes())


def make(cfg: dict, dest: Path, preview: Path):
    w,h=cfg['resolution']; dest.mkdir(parents=True,exist_ok=True);preview.mkdir(parents=True,exist_ok=True)
    yy,xx=np.mgrid[0:h,0:w]
    latitude=np.pi*(yy+.5)/h
    azimuth=2*np.pi*(xx+.5)/w
    # Godot built-in panoramic Y-up sky, Z forward.
    directions=np.stack((np.sin(latitude)*np.sin(azimuth),np.cos(latitude),-np.sin(latitude)*np.cos(azimuth)),axis=2).astype(np.float32)
    manifest={"engine":"Godot 4.6.3 Mobile; actual radiance map, no synthetic model image", "resolution":[w,h],"results":{}}
    for variant,entry in cfg['variants'].items():
        rgb=np.broadcast_to(np.array([.9,1.,1.10],dtype=np.float32)*cfg['background_energy'],(h,w,3)).copy()
        source_measurements=[]
        for source in entry['sources']:
            axis=np.asarray(source['direction'],dtype=np.float32);axis/=np.linalg.norm(axis)
            dot=np.clip(np.sum(directions*axis,axis=2),-1,1)
            radius=math.radians(source['radius_degrees'])
            angle=np.arccos(dot)
            # REAL ROUND CIRCULAR DIFFUSER: angularly isotropic, feathered edge.
            # No rectangular light-card geometry or fourth-power superellipse.
            feather=radius*source['edge_softness']
            edge=np.clip((radius-angle)/feather,0,1)
            smooth=edge*edge*(3-2*edge)
            if source.get('inner_radius_degrees',0)>0:
                inner=math.radians(source['inner_radius_degrees'])
                inner_feather=inner*.22
                inner_edge=np.clip((angle-inner)/inner_feather,0,1)
                smooth*=inner_edge*inner_edge*(3-2*inner_edge)
            if not np.all(np.isfinite(smooth)) or smooth.max()<=0:raise AssertionError(source)
            added=smooth[:,:,None]*source['intensity']*np.asarray(source['rgb'],dtype=np.float32)
            rgb+=added
            source_measurements.append({"name":source['name'],"angular_radius_deg":source['radius_degrees'],"pixels_inside_circle":int((angle<radius).sum()),"peak_radiance":float(added.max())})
        assert np.all(np.isfinite(rgb)) and np.min(rgb)>0
        path=dest/f'overhead_owner_{variant}.hdr';write_hdr(path,rgb)
        # Visualize radiance field ONLY: no mock D20, no fake final product image.
        from PIL import Image
        mapped=np.power(np.clip(rgb/(rgb+1),0,1),1/2.2)
        Image.fromarray((mapped*255).astype(np.uint8),'RGB').save(preview/f'hdr_radiance_{variant}.png')
        manifest['results'][variant]={"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"bytes":path.stat().st_size,"sources":source_measurements,"mean_linear_rgb":float(rgb.mean()),"max_linear_rgb":float(rgb.max()),"source_pbr_changed":False}
    (preview/'original_source_hdr_manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
    print('PASS_3_TRUE_CIRCULAR_DIFFUSER_HDR',json.dumps(manifest['results'],ensure_ascii=False),flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--config',type=Path,required=True);p.add_argument('--dest',type=Path,required=True);p.add_argument('--preview',type=Path,required=True)
    a=p.parse_args()
    make(json.loads(a.config.read_text()),a.dest,a.preview)