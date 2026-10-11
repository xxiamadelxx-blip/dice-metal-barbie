"""Adapter regression uses synthetic source image, NOT a neural model."""
import json
import sys
import tempfile
from pathlib import Path
from PIL import Image
from ai_d20_glb_experiment import run, read_glb

source=Path(sys.argv[1])
with tempfile.TemporaryDirectory() as directory:
    root=Path(directory)
    synthetic=Image.new("RGB",(96,96))
    for y in range(96):
        for x in range(96):
            synthetic.putpixel((x,y),(25+x//3,21+y//4,19+(x+y)%17))
    image=root/"synthetic_TEST_ONLY.png"
    synthetic.save(image)
    candidate=root/"experiment.glb"
    report=root/"test_result.json"
    run(source,image,candidate,report)
    result=json.loads(report.read_text())
    assert result["geometry_unchanged"]
    assert result["accessors_and_number_map_unchanged"]
    assert result["bronze_normal_roughness_unchanged"]
    assert result["new_unique_colors"]>500
    assert result["Godot_visual_acceptance"]=="NOT_VERIFIED"
    original_mesh, original_bin=read_glb(source)
    new_mesh, new_bin=read_glb(candidate)
    assert original_mesh["meshes"]==new_mesh["meshes"]
    assert original_mesh["accessors"]==new_mesh["accessors"]
    assert original_mesh["materials"]==new_mesh["materials"]
    assert original_mesh["bufferViews"]==new_mesh["bufferViews"][:len(original_mesh["bufferViews"])]
    assert original_bin==new_bin[:len(original_bin)]
    print("PASS D20 GLB A/B material adapter: canonical geometry, original PBR, numeric mapping immutable; fixture NOT AI")
