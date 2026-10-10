# Changelog

## Unreleased / M3 developer build · 2026-10-10
- Implemented real physical, individually numbered D4, D6, D8, D12 and D20 on bounded black velvet table with strictly overhead camera.
- Real Jolt rigid-body motion; secure, unbiased pre-roll rotational symmetry selection; final UI value equals physical uppermost face after sleep in tested simulations. No post-roll face snap.
- D8: 269 geometry checks; 12/12 throws and 167 physical assertions.
- D4: regular tetrahedron, 12 apex-marking glyphs, 142 geometry checks, 12/12 physical throws / 175 checks; correct UI default picker selection.
- D12: dual of regular icosahedron with 20 vertices/12 pentagons/60 proper rotations, 1542 mathematical checks; 10/10 throws and 151 physical assertions.
- Hardened D6, D8 and D20 against rare Jolt edge-rest sleeps with bounded small physical nudges. Unresolved outcomes remain errors. Strict integration tests no longer call invalid throws completed.
- CI Android debug APK versionCode 6, `0.0.6-m3-d4`. [Verified run](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38054012551). Signature remains debug-only.
- NOT VERIFIED: device install/upgrade, display and audio quality, long-run statistical fairness, D10/D100, full mechanics, release key.
