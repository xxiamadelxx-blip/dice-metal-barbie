"""Render both private GLBs in the original Blender scene, with identical lights.

blender -b --python-exit-code 1 --python this.py -- --source-scene private.blend
  --control original.glb --candidate authored.glb --output private-render-dir
"""
import argparse
import hashlib
import sys
from pathlib import Path

import bpy

SOURCE_SHA = '3ff237798e8b2498070f886ca43071e43156034358b3694cd7f6c90a63a77cae'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-scene', type=Path, required=True)
    parser.add_argument('--control', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    assert hashlib.sha256(args.source_scene.read_bytes()).hexdigest() == SOURCE_SHA
    args.output.mkdir(parents=True, exist_ok=True)
    for name, model in [('control', args.control), ('candidate', args.candidate)]:
        bpy.ops.wm.open_mainfile(filepath=str(args.source_scene))
        for obj in list(bpy.data.objects):
            if obj.type == 'MESH' and (obj.name.startswith('Canonical_D20') or obj.name.startswith('Gold_')):
                bpy.data.objects.remove(obj, do_unlink=True)
        bpy.ops.import_scene.gltf(filepath=str(model))
        scene = bpy.context.scene
        assert scene.camera is not None, 'Missing original studio camera'
        scene.render.engine = 'CYCLES'
        scene.cycles.samples = 96
        scene.cycles.use_denoising = False
        scene.render.threads_mode = 'FIXED'
        scene.render.threads = 8
        scene.render.resolution_x = 1200
        scene.render.resolution_y = 1200
        scene.render.resolution_percentage = 100
        scene.render.filepath = str(args.output / ('blender-' + name + '.png'))
        bpy.ops.render.render(write_still=True)
        print('REAL_BLENDER_COMPARISON', name, hashlib.sha256(model.read_bytes()).hexdigest(), flush=True)


if __name__ == '__main__':
    main()
