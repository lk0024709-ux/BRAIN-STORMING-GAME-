"""Validate GLB structure, textures, UVs and meter-scale ground-centered bounds."""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {'garage': (10,4,8), 'sniper_tower': (4,10,4),
            'house_small': (6,3.5,6), 'warehouse': (15,6,10)}


def main():
    for name, size in EXPECTED.items():
        path = ROOT / 'docs/models/buildings' / (name + '.glb')
        data = path.read_bytes()
        magic, version, length = struct.unpack_from('<4sII', data)
        assert magic == b'glTF' and version == 2 and length == len(data)
        json_length, kind = struct.unpack_from('<II', data, 12)
        assert kind == 0x4E4F534A
        gltf = json.loads(data[20:20+json_length])
        assert not any('uri' in b for b in gltf['buffers'])
        assert gltf['images'] and all('bufferView' in im for im in gltf['images'])
        for mat in gltf['materials']:
            assert 'baseColorTexture' in mat['pbrMetallicRoughness']
        lo, hi = [float('inf')]*3, [float('-inf')]*3
        for node in gltf['nodes']:
            assert all(abs(v) < 1e-5 for v in node.get('translation', [0,0,0]))
            if 'mesh' not in node:
                continue
            for prim in gltf['meshes'][node['mesh']]['primitives']:
                assert 'TEXCOORD_0' in prim['attributes']
                acc = gltf['accessors'][prim['attributes']['POSITION']]
                for i in range(3):
                    lo[i] = min(lo[i], acc['min'][i])
                    hi[i] = max(hi[i], acc['max'][i])
        for actual, expected in zip([hi[i]-lo[i] for i in range(3)], size):
            assert abs(actual-expected) < 1e-4, (name, lo, hi, size)
        assert abs(lo[1]) < 1e-5
        assert abs(lo[0]+hi[0]) < 1e-5 and abs(lo[2]+hi[2]) < 1e-5
        print(f'{name}: OK; bounds={lo}..{hi}; {len(data):,} bytes; embedded textures + UVs')


if __name__ == '__main__':
    main()
