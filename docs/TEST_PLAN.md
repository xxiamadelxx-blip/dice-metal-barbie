# Test plan

## Automated gates
- Engine project imports headlessly without script parse failures.
- Deterministic RNG injection: inclusive endpoints, rejection of biased tail, percentile 00+0, advantage/disadvantage, critical boundaries, modifiers.
- Add parser, roll ranges, statistical fairness, face mapping, contact and persistence tests before implementing their features.
- Android arm64 debug export is nonzero and artifact exists. APK inspection, install and logcat required at later stages.

## M3 statistical checks (to implement)
For each die `N`, use fixed sample budget (proposal: >=100,000 outcomes per type) and chi-square goodness-of-fit with a chosen significance threshold; validate test power and false-positive rate, don't test only means. Confirm each visual face mapping exactly, and run simulated thousands of throws for out-of-bounds, timeouts and sleep stability. Sampling must use crypto RNG, not sandbox randf.

## Device validation
OnePlus Nord 3: real 60 FPS target, 99% of ordinary rolls settle <=8 seconds, no clipping or teleports, no persistent stalled throws. Verify closed/offline start, repeated throws, rotate/background/resume, collision sound vs contact, haptic support, selection state, 1/20 glow, copy and history, upgrade-over-install with release key. Record measured results / NOT VERIFIED if absent.

## Review protocol
Each critical change has criteria, CI logs or actual files, reproduction steps, critic review if independent capacity exists, outcome PASS/FAIL/NOT VERIFIED. Green CI is not a proxy for aesthetics or hardware tests.

