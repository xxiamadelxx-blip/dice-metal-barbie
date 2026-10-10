"""Locate a genuine Android system fullscreen 'Got it' button from ADB screenshot.

Print "x y" when visible, empty when absent, exit 2 if system dialog exists
without a safely localized button. Never treat this as gameplay readiness.
"""
import sys
from pathlib import Path
from PIL import Image

def locate(image: Image.Image):
    rgb=image.convert("RGB")
    width,height=rgb.size
    if width<450 or height<700:
        raise ValueError(f"Unexpected Android viewport {width}x{height}")
    scale=lambda x,y: (round(x*width/720),round(y*height/1280))
    pale=[rgb.getpixel(scale(x,y)) for x,y in [(80,120),(180,220),(260,320)]]
    present=all(min(p)>185 and max(p)-min(p)<35 for p in pale)
    if not present:
        return None
    x0,y0=scale(460,270)
    x1,y1=scale(708,480)
    matches=[]
    step=max(1,round(width/720))
    for y in range(y0,min(height,y1),step):
        for x in range(x0,min(width,x1),step):
            r,g,b=rgb.getpixel((x,y))
            if 34<=r<=145 and 48<=g<=170 and 85<=b<=215 and b-r>28 and b-g>20:
                matches.append((x,y))
    min_pixels=max(250,round(width*height/720/1280*1600))
    if len(matches)<min_pixels:
        raise RuntimeError("Android fullscreen dialog present, but Got it "
                           f"button not identified ({len(matches)} blue pixels)")
    cx=round(sum(x for x,y in matches)/len(matches))
    cy=round(sum(y for x,y in matches)/len(matches))
    if not (x0<=cx<x1 and y0<=cy<y1):
        raise RuntimeError(f"Unsafe Android dialog coordinates {cx},{cy}")
    return cx,cy

if __name__=="__main__":
    try:
        target=locate(Image.open(Path(sys.argv[1])))
        if target is not None:
            print(*target)
    except (OSError,ValueError,RuntimeError) as exc:
        print(f"Android immersive dialog detection FAILED: {exc}",file=sys.stderr)
        raise SystemExit(2)
