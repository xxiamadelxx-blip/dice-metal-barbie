"""Check actual spatial content of 1024px D20 geometric AO in CI.

A previous 'PASS' AO file had 443392 pure-white pixels, 604160 black
pixels and only ONE midgray row: a baked stripe rather than real relief.
This independent gate rejects it even though global standard deviation
and file dimensions passed. Spatial heuristics do not replace art review.
"""
from pathlib import Path
import json
import sys

import numpy as np
from PIL import Image

def inspect(path):
    arr=np.asarray(Image.open(path).convert("L"),dtype=np.float32)/255
    assert arr.shape==(1024,1024), 'D20 AO must be 1024x1024'
    vals=np.quantile(arr,[.01,.5,.99])
    result={
        'file':str(path),
        'p01':float(vals[0]), 'p50':float(vals[1]), 'p99':float(vals[2]),
        'std':float(arr.std()),
        'midtone_fraction':float(np.mean((arr>.075)&(arr<.925))),
        'rows_with_horizontal_detail':float(np.mean(arr.std(axis=1)>.015)),
        'cols_with_vertical_detail':float(np.mean(arr.std(axis=0)>.015)),
        'mean_horizontal_gradient':float(np.mean(np.abs(np.diff(arr,axis=1))))
    }
    print(json.dumps(result,indent=2))
    assert result['midtone_fraction']>.008, 'AO lacks grayscale penumbrae'
    assert result['rows_with_horizontal_detail']>.06, (
        'AO is only a horizontal band, NOT numbers/cavity shading')
    assert result['cols_with_vertical_detail']>.06, 'AO has no per-column detail'
    assert result['mean_horizontal_gradient']>.001, 'No horizontal AO texture detail'
    return result

if __name__=='__main__':
    inspect(Path(sys.argv[1] if len(sys.argv)>1 else 'build/premium-glb/d20_geometry_baked_ao.png'))
