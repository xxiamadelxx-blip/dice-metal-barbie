# M3 · physical D12

Regular dodecahedron built as the exact dual of the validated icosahedron. Each of 12 planar pentagonal faces is associated with an original icosahedron vertex; each of 20 dodecahedron vertices comes from an original triangle center. SurfaceTool draws 36 flat-shaded triangles; Jolt ConvexPolygonShape3D uses the unmodified 20-point symmetric hull. The 12 labels are pure visual meshes, not part of collider/mass.

Before launch, Crypto entropy picks one of 60 proper icosahedral symmetries; each D12 face has exactly 5 eligible transformations. Physical result is **not** predetermined or altered after flight. It is measured from the final visible top face after Jolt sleep. Opposite values sum to 13.

- `tests/d12_geometry.gd`: dual topology, 20 vertices, 12 coplanar pentagons, opposite numbering, 60 proper symmetries preserving the vertex set, equal label multiplicity
- `tests/numbered_d12_physics.gd`: real D12 convex body, 12 face-aligned labels, 10 live Jolt throws, top face == UI, bounded table and input lock
- Prior D6/D8/D20 regression suites and Android ARM64 debug export run unchanged

Real phone legibility, larger statistical distribution tests, independent critic, sound/haptics, D4/D10/D100 and final UI NOT VERIFIED.
