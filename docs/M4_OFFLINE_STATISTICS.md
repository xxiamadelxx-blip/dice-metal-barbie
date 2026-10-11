# M4 offline history statistics candidate

M4 approved PRD calls for local statistics. The existing hidden **ИСТОРИЯ** view now derives a compact summary from stored actual-Jolt-source receipts: selected result count, average signed formula total, minimum/maximum, natural selected-D20 critical success/failure counts, and records containing a physical reroll. Search filters update the summary. No backend, new skin, physical value changes or disk writes.

**Meaningful limitation:** a selected physical reroll creates another history receipt and may repeat unmodified dice from the earlier receipt. This is **not** independent die-face frequency data or proof of fair dice. Say so in the UI. The store currently retains up to 200 recent receipts. Source-marker and numeric bounds exclude obviously ineligible rows, but no provenance string alone proves a physical outcome.

Acceptance requires the deterministic test-only `tests/m4_roll_statistics.gd` **and** the existing full production Godot/Jolt UI test `tests/m4_full_history_browser.gd` after actual throw, reroll, saved history and search, plus the original 24fps popup timeline. Until exact-commit CI, status **NOT VERIFIED**. This staging branch must be merged back into PR #23 only after its prior Android D100 source workflow has finished, preserving verified models/changes.
