"""No-install GLB geometry, signature, number map and PNG checks (stdlib)."""
import json
import struct
import sys
from pathlib import Path

def validate(root):
    manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
    assert '4.0' in manifest['blender'] or manifest['blender'].startswith('4.'), 'Blender 4 required'
    pbr=manifest.get('pbr',{})
    assert pbr.get('size')==256 and len(pbr.get('images',[]))==3, 'PBR texture source files missing'
    assert .03 < pbr.get('albedo_linear_mean',-1) < .13, 'Obsidian albedo too bright for charcoal material'
    for filename in pbr['images']:
        png=(root/filename).read_bytes()
        assert png[:8]==bytes.fromhex("89504e470d0a1a0a") and len(png)>8000, 'Empty texture '+filename
    look=manifest['dice']['D20'].get('lookdev',{})
    assert look.get('uv_layout')=='numbered_face_planar_5x4', 'D20 requires real separate planar face UV atlas'
    assert look.get('pbr_resolution')==1024, 'D20 high-resolution lookdev textures missing'
    ao=look.get('ao',{})
    assert ao.get('bake','').startswith('Blender Cycles AO'), 'AO must be genuinely Cycles baked'
    assert ao.get('runtime_ao')=='NOT_IN_GLTF_YET_IMPORT_TEST_REQUIRED', (
        'Do not claim an AO map is imported when its runtime hookup is untested')
    assert ao.get('cavity_pixels',0)>2000 and ao.get('cavity_min',1.0)<.88, (
        'AO bake has no significant engraved surface cavity shadow')
    assert ao.get('luma_std',0)>.025 and ao.get('dark_fraction',1.0)<.65, (
        'AO image uniformly black or nonphysical: fail closed')
    for name in [ao['file'],'d20_obsidian_albedo.png',
                 'd20_obsidian_roughness.png','d20_obsidian_normal.png']:
        raw=(root/name).read_bytes()
        assert raw[:8]==bytes.fromhex("89504e470d0a1a0a"), 'D20 actual bake or PBR PNG missing'
        width,height=struct.unpack_from('>II',raw,16)
        assert (width,height)==(1024,1024), 'D20 actual UV/texture resolution incorrect: '+name
        assert len(raw)>10000, 'D20 PNG is empty/flat '+name
    for sides in (20,6,8,12,4):
        entry=manifest['dice'][f'D{sides}']
        values=entry['numbers']
        assert entry.get('underbar_numbers')==[v for v in values if v in (6,9)], f'D{sides} 6/9 3D orientation bars missing'
        if sides>4:
            assert 6 in entry['underbar_numbers'], f'D{sides} must mark its numeral 6'
        else:
            assert entry['underbar_numbers']==[], 'D4 apex 1–4 need no 6/9 markers'
        assert len(values)==sides and sorted(values)==list(range(1,sides+1)),f'D{sides} bad numeric face map'
        if sides==20:
            # Opposite faces of a proper D20 should add to 21; same
            # number order expected by the established Godot icosahedron.
            expected=[1,2,3,4,5,6,7,8,9,10,17,18,19,20,16,12,11,15,14,13]
            assert values==expected,'D20 visual index mapping deviates from Jolt'
        if sides==6:
            assert values==[1,6,2,5,3,4],'D6 visual index mapping deviates from Jolt'
        if sides==4:
            assert values==[1,2,3,4] and entry.get('engraved_glyphs')==12, 'D4 requires three imprints per apex (12 total)'
        if sides==8:
            assert values==list(range(1,9)),'D8 visual index mapping deviates from Jolt'
        if sides==12:
            assert values==[1,2,11,12,3,4,9,10,5,6,7,8], 'D12 visual index mapping deviates from Jolt'
        blob=(root/entry['glb']).read_bytes()
        assert len(blob)==entry['glb_bytes'] and len(blob)>40000,f'D{sides} empty GLB'
        magic,version,length=struct.unpack_from('<4sII',blob,0)
        assert (magic,version,length)==(b'glTF',2,len(blob)),f'D{sides} malformed GLB header'
        chunk_bytes,chunk_type=struct.unpack_from('<I4s',blob,12)
        assert chunk_type==b'JSON' and chunk_bytes>100, 'missing GLB scene JSON'
        scene=json.loads(blob[20:20+chunk_bytes].decode('utf-8'))
        assert scene['asset']['version']=='2.0'
        assert len(scene['meshes'])==2 and len(scene['materials'])>=2, f'D{sides} missing stone or engraved gold'
        assert len(scene.get('textures',[]))>=2 and len(scene.get('images',[]))>=2, f'D{sides} GLB missing embedded texture maps'
        pbr_materials=[m for m in scene['materials']
                       if m.get('normalTexture') and m.get('pbrMetallicRoughness',{}).get('baseColorTexture')
                       and m.get('pbrMetallicRoughness',{}).get('metallicRoughnessTexture')]
        assert len(pbr_materials)>=1, f'D{sides} GLB missing albedo/roughness/normal surface contract'
        if sides==20:
            # Verify REAL UV0 binary float coordinates, not just manifest
            # text. Old export had all (0,1) UV0 for the first primitive and
            # the correct 20 face atlas silently in TEXCOORD_1.
            source_material=pbr_materials[0]
            pbr=source_material['pbrMetallicRoughness']
            for slot in (pbr['baseColorTexture'],
                         pbr['metallicRoughnessTexture'],
                         source_material['normalTexture']):
                assert slot.get('texCoord',0)==0, 'D20 material samples non-primary UV'
            atlas_cells=set()
            glb_buffer_start=20+chunk_bytes+8
            for prim in scene['meshes'][0]['primitives']:
                uv_id=prim['attributes']['TEXCOORD_0']
                acc=scene['accessors'][uv_id]
                assert acc['type']=='VEC2' and acc['componentType']==5126
                view=scene['bufferViews'][acc['bufferView']]
                pos=glb_buffer_start+view.get('byteOffset',0)+acc.get('byteOffset',0)
                coords=memoryview(blob)[pos:pos+acc['count']*8]
                assert len(coords)==acc['count']*8
                for u,v in struct.iter_unpack('<ff',coords):
                    if 0<=u<1 and 0<=v<1:
                        atlas_cells.add((min(4,int(u*5)),min(3,int(v*4))))
            assert len(atlas_cells)==20, (
                'D20 PRIMARY UV0 missing 5x4 face atlas, cells=%s'
                % sorted(atlas_cells))
            print('PASS primary glTF D20 UV0 all 20 atlas cells and PBR maps')
        for mesh in scene['meshes']:
            assert mesh['primitives'], f'D{sides} missing render primitives'
            for primitive in mesh['primitives']:
                assert 'POSITION' in primitive['attributes']
                if mesh==scene['meshes'][0]:
                    assert 'TEXCOORD_0' in primitive['attributes'],f'D{sides} no stone UV map'
                pos=scene['accessors'][primitive['attributes']['POSITION']]
                indices=scene['accessors'][primitive['indices']]
                assert pos['count']>100 and indices['count']>300
        stone=scene['meshes'][0]['primitives'][0]
        position=scene['accessors'][stone['attributes']['POSITION']]
        mins,maxs=position['min'],position['max']
        expected_half={6:.61,20:.7486,8:.93,12:.98,4:.566}[sides]
        for bound in [*mins,*maxs]:
            assert abs(bound)<=expected_half+.015,f'D{sides} shell exceeds original Jolt hull'
        assert entry['triangles']>sides*5, f'D{sides} no cut mesh detail'
        qa_ply=(root/f'd{sides}_stone_qa.ply').read_text()
        assert qa_ply.startswith('ply\nformat ascii 1.0\n')
        assert 'element vertex ' in qa_ply and 'element face ' in qa_ply
        assert qa_ply.count('\n3 ')>sides*2 and len(qa_ply)>1000, f'D{sides} PLY for MeshLab QA not valid'
        preview=(root/entry['preview']).read_bytes()
        assert preview[:8]==b'\x89PNG\r\n\x1a\n' and len(preview)>50000,f'D{sides} missing true Blender preview'
        print(f'PASS D{sides}: {len(blob):,} bytes, {entry["triangles"]} Blender shell polygons, 2 meshes, exact face numbering, real PNG')
    print('PASS: five actual exported GLBs and Blender scene captures validated')

if __name__=='__main__':
    validate(Path(sys.argv[1] if len(sys.argv)>1 else 'build/premium-glb'))
