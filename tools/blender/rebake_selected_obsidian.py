"""Bake the licensed source's actual bump into a portable 2K black PBR material.

Run in Blender with --python-exit-code 1. No generated/painted stone pattern.
The input geometry is a private review candidate, never the physics collider.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

import bpy
import numpy as np

SOURCE_BLEND_SHA = '3ff237798e8b2498070f886ca43071e43156034358b3694cd7f6c90a63a77cae'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-blend', required=True, type=Path)
    parser.add_argument('--geometry', required=True, type=Path)
    parser.add_argument('--geometry-sha', required=True)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--wave-strength', type=float, default=.025)
    parser.add_argument('--noise-strength', type=float, default=.0007)
    parser.add_argument('--wave-scale', type=float, default=5.0)
    parser.add_argument('--noise-scale', type=float, default=3.0)
    parser.add_argument('--roughness', type=float, default=.09)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    assert hashlib.sha256(args.source_blend.read_bytes()).hexdigest() == SOURCE_BLEND_SHA
    assert hashlib.sha256(args.geometry.read_bytes()).hexdigest() == args.geometry_sha
    assert 0 < args.roughness <= 1 and 0 <= args.wave_strength <= .2
    assert 0 <= args.noise_strength <= .05
    assert 0 < args.wave_scale <= 30 and 0 < args.noise_scale <= 30
    args.output.mkdir(parents=True, exist_ok=True)
    # Open the source as a main file so Blender runs its file-version migration
    # on the entire node graph; appending only its material is insufficient.
    bpy.ops.wm.open_mainfile(filepath=str(args.source_blend))
    authored = bpy.data.materials['Procedural Obsidian']
    authored.use_fake_user = True
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=str(args.geometry))
    stone = next(o for o in bpy.data.objects if o.name.startswith('Canonical_D20'))
    group = next(n for n in authored.node_tree.nodes if n.type == 'GROUP')
    # Library append of an older Principled node can retain obsolete sockets.
    # Recreate its three linked inputs on this runtime's native node. Preserve
    # the actual source wave/noise network rather than silently baking flat.
    tree = group.node_tree
    old_shader = next(n for n in tree.nodes if n.type == 'BSDF_PRINCIPLED')
    native_shader = tree.nodes.new('ShaderNodeBsdfPrincipled')
    native_shader.inputs['Metallic'].default_value = 0
    native_shader.inputs['IOR'].default_value = 1.45
    for socket_name in ['Base Color', 'Roughness', 'Normal']:
        assert old_shader.inputs[socket_name].is_linked, ('Missing authored connection', socket_name)
        link = old_shader.inputs[socket_name].links[0]
        tree.links.new(link.from_socket, native_shader.inputs[socket_name])
    if 'Weight' in native_shader.inputs:
        native_shader.inputs['Weight'].default_value = 1.0
    outgoing = [link.to_socket for link in old_shader.outputs['BSDF'].links]
    assert outgoing
    for target in outgoing:
        tree.links.new(native_shader.outputs['BSDF'], target)
    tree.nodes.remove(old_shader)
    group.inputs['Roughness'].default_value = args.roughness
    group.inputs['wave bump Strength'].default_value = args.wave_strength
    group.inputs['noise bump Strength'].default_value = args.noise_strength
    group.inputs['wave Scale'].default_value = args.wave_scale
    group.inputs['noise Scale'].default_value = args.noise_scale
    for index in range(len(stone.data.materials)):
        stone.data.materials[index] = authored
    bpy.ops.object.select_all(action='DESELECT')
    stone.select_set(True)
    bpy.context.view_layer.objects.active = stone
    # The source atlas projects multiple triangular faces into shared square
    # charts. It is valid for its old maps but not for a fresh tangent bake:
    # overlapping faces overwrite each other's different tangent directions.
    # Author a unique unwrap for this candidate before baking its source bump.
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=.6, island_margin=.015,
                             area_weight=1.0, correct_aspect=True, scale_to_bounds=True)
    bpy.ops.object.mode_set(mode='OBJECT')
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 32
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 8
    scene.render.bake.margin = 16
    scene.render.bake.use_selected_to_active = False
    scene.render.bake.normal_space = 'TANGENT'
    normal_image = bpy.data.images.new('Actual_Source_Waves_2K', width=2048, height=2048, alpha=False)
    normal_image.colorspace_settings.name = 'Non-Color'
    bake_node = authored.node_tree.nodes.new('ShaderNodeTexImage')
    bake_node.image = normal_image
    authored.node_tree.nodes.active = bake_node
    bpy.ops.object.bake(type='NORMAL')
    pixels = np.empty(2048 * 2048 * 4, dtype=np.float32)
    normal_image.pixels.foreach_get(pixels)
    pixels = pixels.reshape(-1, 4)
    encoded = pixels[pixels[:, 2] > .8, :2]
    assert len(encoded) > 10000, 'No valid normal bake pixels'
    channel_range = np.ptp(encoded, axis=0)
    print('ACTUAL_NORMAL_PIXEL_RANGE', channel_range.tolist(), 'valid pixels', len(encoded), flush=True)
    assert float(channel_range.max()) > .03, 'Source bump missing: flat normal bake'
    normal_image.filepath_raw = str(args.output / 'source-wave-normal-2k.png')
    normal_image.file_format = 'PNG'
    normal_image.save()
    baked = bpy.data.materials.new('Selected_Obsidian_Actual_Source_Waves_2K')
    baked.use_nodes = True
    shader = baked.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (0, 0, 0, 1)
    shader.inputs['Metallic'].default_value = 0
    shader.inputs['IOR'].default_value = 1.45
    shader.inputs['Roughness'].default_value = args.roughness
    texture = baked.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = normal_image
    normal = baked.node_tree.nodes.new('ShaderNodeNormalMap')
    baked.node_tree.links.new(texture.outputs['Color'], normal.inputs['Color'])
    baked.node_tree.links.new(normal.outputs['Normal'], shader.inputs['Normal'])
    for index in range(len(stone.data.materials)):
        stone.data.materials[index] = baked
    bpy.ops.object.select_all(action='DESELECT')
    for obj in scene.objects:
        if obj.type == 'MESH':
            obj.select_set(True)
    glb = args.output / 'candidate-source-wave-obsidian.glb'
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format='GLB', use_selection=True,
                             export_apply=True, export_texcoords=True, export_normals=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output / 'candidate-source-wave-obsidian.blend'))
    receipt = {'blender': bpy.app.version_string, 'source_blend_sha256': SOURCE_BLEND_SHA,
               'geometry_sha256': args.geometry_sha, 'candidate_sha256': hashlib.sha256(glb.read_bytes()).hexdigest(),
               'bake': 'actual licensed source material, Cycles tangent normal, 2048x2048, 32 samples',
               'uv': 'Blender Smart UV; unique chart unwrap before tangent bake, angle .6, margin .015',
               'wave_strength': args.wave_strength, 'noise_strength': args.noise_strength,
               'wave_scale': args.wave_scale, 'noise_scale': args.noise_scale,
               'roughness': args.roughness, 'base_color': [0, 0, 0], 'metallic': 0,
               'source_principled_migration': 'native node; source Base Color/Roughness/Normal links preserved',
               'valid_normal_pixels': len(encoded), 'normal_xy_range': channel_range.tolist(),
               'gold_material_unchanged': True, 'physics_changes': False,
               'artistic_acceptance': 'NOT_VERIFIED'}
    (args.output / 'material-receipt.json').write_text(json.dumps(receipt, indent=2))
    print('ACTUAL_SOURCE_REBAKE', json.dumps(receipt), flush=True)


if __name__ == '__main__':
    main()
