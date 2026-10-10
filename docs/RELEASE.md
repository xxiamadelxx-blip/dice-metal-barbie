# Release and signing

**M2:** CI produces Android debug artifact only. The keystore in the CI image is an untrusted debug identity for development, **not** the permanent update identity.

**M6 required:**
1. Generate a unique strong keystore once, back it up privately. Never put secret or keystore file in git / artifacts / logs.
2. Store encrypted keystore bytes and alias/password as protected GitHub Actions secrets (with explicit owner authorization to configure secrets).
3. Export Android release with stable applicationId `org.dicemetalbarbie.dnddice`, monotonically increasing versionCode, and never change release key without planned migration.
4. Verify certificate fingerprint, package ID, install/update without data loss, offline launch and core behavior on Nord 3.
5. Only then publish tagged GitHub Release with signed APK, SHA-256, CHANGELOG and test evidence.

No claim of release-ready APK before these steps.

