# M5 physically triggered soft velvet tabletop response
User reference: Alpha 4.0.0's CSS tray kick (.14s, 1.5px). Approved 90-degree overhead Godot/Jolt scene, true impact over the physical felt floor. No whole-camera movement or fictitious physics.

## Exact implementation
- Existing VelvetTable StaticBody3D and collision box DO NOT MOVE. Keep full-weight 3D die objects/face maps and recording unchanged.
- New dense VISUAL PlaneMesh using the same procedural velvet color and normal textures. Offset original purely visual tabletop down by 12mm to leave room for an independent visibly depressed vertex surface. No new collider.
- `src/visual/velvet_contact.gdshader`: Gaussian local y depression **up to 12mm**, faint moving nap-compression edge, 250ms cubic-like decay; all else stable.
- `src/visual/velvet_impact.gd`: explicit register_impact only with speed >.16, positive mass and a location inside tabletop; strength clamped from **observed speed × physical die mass**. This is an estimate, not a measured Jolt impulse. No idle loop. Last few rapid hits replace earlier pulse; multi-impact accumulation reserved for polish.
- `src/main.gd`: RigidBody3D `contact_monitor=true` / `max_contacts_reported>=8`; listen for *real* body_entered **only** when body == named VelvetTable. Attach to actual single D4/D6/D8/D10/D12/D20/D100 bodies, both physically independent percentile D10, and every body launched by the mixed physical pool via a new `physical_die_spawned` signal.
- M4 actual top face, D4 apex, crit classification, collider, weights and offline storage are not modified.
- `tests/m5_real_felt_contact.gd` proves idle/no-speed produces no pulse, then performs a genuine D6 throw, demands a true Jolt floor contact, verifies floor shape pointer unchanged, and 250ms recovery. Full Jolt/native render/24fps/Android AVD still mandatory.

**Acceptance status** CANDIDATE ONLY until exact-head Gauntlet checks and original video screenshots confirm subtle visual response. Don't confuse shader existence or a manually called impact with measured physical mobile appearance. Actual OnePlus Nord 3 haptics and source contact sound remain separate M5/M6 gates.
