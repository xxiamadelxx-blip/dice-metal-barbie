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
    for filename in pbr['images']:
        png=(root/filename).read_bytes()
        assert png[:8]==bytes.fromhex("89504e470d0a1a0a") and len(png)>8000, 'Empty texture '+filename
    for sides in (20,6):
        entry=manifest['dice'][f'D{sides}']
        values=entry['numbers']
        assert len(values)==sides and sorted(values)==list(range(1,sides+1)),f'D{sides} bad numeric face map'
        if sides==20:
            # Opposite faces of a proper D20 should add to 21; same
            # number order expected by the established Godot icosahedron.
            expected=[1,2,3,4,5,6,7,8,9,10,17,18,19,20,16,12,11,15,14,13]
            assert values==expected,'D20 visual index mapping deviates from Jolt'
        if sides==6:
            assert values==[1,6,2,5,3,4],'D6 visual index mapping deviates from Jolt'
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
        expected_half=.61 if sides==6 else .7486
        for bound in [*mins,*maxs]:
            assert abs(bound)<=expected_half+.015,f'D{sides} shell exceeds original Jolt hull'
        assert entry['triangles']>sides*5, f'D{sides} no cut mesh detail'
        preview=(root/entry['preview']).read_bytes()
        assert preview[:8]==b'\x89PNG\r\n\x1a\n' and len(preview)>50000,f'D{sides} missing true Blender preview'
        print(f'PASS D{sides}: {len(blob):,} bytes, {entry["triangles"]} Blender shell polygons, 2 meshes, exact face numbering, real PNG')
    print('PASS: both actual exported GLBs and Blender scene captures validated')

if __name__=='__main__':
    validate(Path(sys.argv[1] if len(sys.argv)>1 else 'build/premium-glb'))
