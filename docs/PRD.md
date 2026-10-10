# PRD — approved M0

**State:** Product concept approved 2026-10-10. This document captures requirements; completion status is governed by the Milestones and Acceptance Criteria files.

## Product
Personal fully offline Android 3D D&D dice simulator for OnePlus Nord 3, with no registration.

### Primary journey
Open directly on black velvet table, view strictly from above. Compact minimal controls beneath; choose standard die and quantity, press Throw. Physically simulated black obsidian dice enter from upper side without hand, hit, bounce, spin and settle inside bounded table. The physically visible numbered face equals genuine random outcome; result is shown separately and can be copied. A natural 1/20 on D20 triggers distinct glow/aura/flash originating at that die. Sound and haptic events correspond to real collisions. User cannot accidentally scroll or interfere during live throw. History persists after relaunch.

### Mechanics
- Physical D4, D6, D8, D10, D12, D20, D100.
- D100 mode selector: real single D100 OR percentile 2×D10, mapping 00+0 to 100.
- Simple single-type controls by default; advanced formulas and mixed groups are intentionally concealed.
- Full formula/modifier/reroll support, advantage/disadvantage per D&D 5e semantics for D20, natural crit on *selected* D20.
- History, statistics, named presets, selected dice and cosmetics saved on device.

### Visual
Use one static distant top-down camera with no tilt; black obsidian/velvet initial set only. Left upper drawer future-proof for skins of dice, tables, trays, towers. Do not expose empty cosmetic catalogs until content exists.

### Later releases
Ornate metallic, bone-white/blue, pastel/gold sets referenced by user images; other surfaces; physical trays and towers; other devices; syncing only with separate approval.

## Non-goals / constraints
No backend, internet calls, monetization, tracking or paid APIs. APK size not a priority, but smoothness, readablity and stability on target phone are gates. No claim of absolute mathematical randomness; unbiased secure entropy is the criterion.

