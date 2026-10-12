"""Numeric regression tests for the actual Blender D20 glTF atlas normal math."""
import unittest
import numpy as np
from tools.blender.d20_micronormal_field import tangent_normal_field


def slope_xy(u, v):
    rgb = tangent_normal_field(np.asarray(u), np.asarray(v))
    return 2 * rgb[..., :2] - 1


class MicroNormalFieldTests(unittest.TestCase):
    def test_tile_border_is_exactly_neutral(self):
        t = np.linspace(0, 1, 256, dtype=np.float32)
        for u,v in ((np.zeros_like(t),t),(np.ones_like(t),t),
                    (t,np.zeros_like(t)),(t,np.ones_like(t))):
            got = tangent_normal_field(u,v)
            np.testing.assert_allclose(got, np.broadcast_to([.5,.5,1],got.shape),
                                       atol=1e-7)

    def test_unit_length_and_finite(self):
        v,u = np.mgrid[0:1024,0:1024].astype(np.float32)
        u = np.mod((u+.5)*5/1024,1)
        v = np.mod((v+.5)*4/1024,1)
        got = tangent_normal_field(u,v)
        self.assertTrue(np.isfinite(got).all())
        unit = 2*got-1
        self.assertLess(float(np.max(np.abs(np.linalg.norm(unit,axis=-1)-1))),1e-5)
        sigma = np.std(got,axis=(0,1))*255
        self.assertGreater(float(sigma[0]),2.1)
        self.assertGreater(float(sigma[1]),2.1)

    def test_no_diagonal_derivative_cusp(self):
        # Old min(4u,4v,...) ramp has >0.25 discontinuity here.
        p,h = .16,.001
        def x(t): return float(slope_xy(t,p)[0])
        jump = abs(x(p+h)-2*x(p)+x(p-h))/h
        self.assertLess(jump,.015,"diagonal stripe/cusp returned")

    def test_rotational_symmetry_and_curl_free_field(self):
        u,v,h=.26,.32,.001
        a=slope_xy(u,v); b=slope_xy(v,u)
        self.assertAlmostEqual(float(a[0]),float(b[1]),places=6)
        self.assertAlmostEqual(float(a[1]),float(b[0]),places=6)
        dnx_dv = (slope_xy(u,v+h)[0]-slope_xy(u,v-h)[0])/(2*h)
        dny_du = (slope_xy(u+h,v)[1]-slope_xy(u-h,v)[1])/(2*h)
        self.assertLess(abs(float(dnx_dv-dny_du)),1e-4)


if __name__ == "__main__":
    unittest.main()
