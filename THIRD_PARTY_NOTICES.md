# Third-Party Notices and Source Provenance

This repository is developed with an evidence-first licensing boundary.

## HDRImageViewer

- Upstream project: `linyusenzz/HDRImageViewer`
- Upstream license: GNU General Public License v3.0 or later (GPL-3.0-or-later)
- Relationship: architectural and diagnostic-design influence is documented in `docs/HDRIMAGEVIEWER_INFLUENCE.md`.
- Current policy: implementation is intended to remain clean-room unless a file-level provenance record explicitly states that upstream code was copied or adapted.

For any future copied or adapted upstream code, the same change must record:

1. upstream repository and exact commit SHA;
2. upstream file path;
3. applicable license and copyright notice;
4. local destination file;
5. whether the material is copied, translated, adapted, or independently reimplemented;
6. material modifications;
7. required attribution or notice text.

Do not merge copied or adapted GPL-covered code without preserving the applicable GPL obligations and attribution.

## Codec and media dependencies

The repository does not intentionally bundle FFmpeg, libplacebo, x265/HEVC codec binaries, Dolby SDKs, DRM-circumvention components, or unlicensed commercial media. Any proposal to add or distribute these components requires a dedicated license, patent, redistribution, and platform-policy review before merge.

## Verification rule

Architecture inspiration is not evidence that source code was copied. Conversely, absence of a provenance note is not proof of clean-room independence. If source provenance is uncertain, treat it as unresolved and complete a source-level comparison before changing the repository's licensing posture.
