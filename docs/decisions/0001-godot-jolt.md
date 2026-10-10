# ADR-0001 · Godot 4.6 + Jolt

Decision approved 2026-10-10. Use Godot 4.6 stable family, pin patch to 4.6.3 for CI; use Jolt physics, GDScript, Mobile renderer. Godot offers complete pipeline with 3D, UI, collisions, exporter and open-source license. Alternatives evaluated: libGDX/Bullet, Kotlin/Filament+physics, Unity. Reserve libGDX/Bullet only on demonstrated blocker, not subjective bias. Reassess with reproducible benchmarks if necessary. Most important risk is honest RNG ↔ exact physical face consistency including real single D100.

