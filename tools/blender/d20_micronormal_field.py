"""Tile-periodic, seam-safe dielectric micro-normal field for the 5x4 D20 UV atlas.

A radial C1-soft bump replaces the old min(edge distances) envelope, whose
piecewise first derivative had diagonal creases in glossy stone reflections.
The field is a true integrable gradient of a compact-support height function.
No surface displacement, material tint or image-space specular painting.
"""
import numpy as np


def tangent_normal_field(u, v, *, slope=0.18, radius=0.49):
    """Return linear tangent-space RGB floats in [0,1] for matching UV arrays.

    Each UV tile has neutral normals outside a radius <0.5 from its center.
    f=(1-r²/R²)^2 inside the circle, zero outside. Both value and first
    derivative smoothly vanish at the radius, including all tile borders.
    In-plane slopes are proportional to (u-.5,v-.5)*f, the analytic gradient
    of a radial scalar height field. This avoids diagonal/ramp cusps.
    """
    if not (0 < radius < 0.5):
        raise ValueError("radius must be inside one UV tile")
    if not (0 <= slope <= 0.3):
        raise ValueError("slope outside audited micro-normal range")
    u = np.asarray(u, dtype=np.float32)
    v = np.asarray(v, dtype=np.float32)
    du = u - np.float32(0.5)
    dv = v - np.float32(0.5)
    r = np.float32(radius)
    falloff = np.maximum(np.float32(0), np.float32(1) -
                         (du * du + dv * dv) / (r * r))
    scale = np.float32(slope) / r * falloff * falloff
    nx = du * scale
    ny = dv * scale
    nz = np.sqrt(np.maximum(np.float32(0), np.float32(1) - nx * nx - ny * ny))
    return np.stack((np.float32(0.5) + np.float32(0.5) * nx,
                     np.float32(0.5) + np.float32(0.5) * ny,
                     np.float32(0.5) + np.float32(0.5) * nz), axis=-1)
