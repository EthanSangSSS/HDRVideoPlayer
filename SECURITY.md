# Security Policy

`HDRVideoPlayer` is a public HDR / Dolby Vision player and diagnostics lab. The main public-safety risks are unlicensed media, codec redistribution, DRM bypass claims, false playback-certification claims, and accidental inclusion of private local media paths or logs.

## Supported scope

Security reports are in scope when they involve:

- bundled secrets, credentials, private keys, signing material, or private logs;
- unlicensed sample media or proprietary codec binaries included in the repository;
- instructions that encourage DRM bypass, codec circumvention, or unauthorized media access;
- false claims of Dolby Vision certification, HDR presentation accuracy, or playback correctness without validation evidence;
- scripts that delete, overwrite, publish, or collect local media without explicit authorization.

## Out of scope

- Requests for proprietary Dolby SDKs, DRM bypass, codec packs, or copyrighted sample files.
- Claims that require access to systems, media, or services not owned by the maintainer.
- General playback bugs without a reproduction outline, sample classification, or public-safe fixture.

## Reporting

Open a GitHub issue if no sensitive media, credentials, or private logs are included. If sensitive material is involved, open a minimal public issue with only:

- affected path or command;
- risk category;
- safe reproduction outline;
- whether private media, paths, or logs may be involved.

Do not upload copyrighted media, private device logs, keys, or proprietary SDK material.

## Maintainer handling SOP

1. Confirm the affected file, command, or documentation claim.
2. Reproduce using public-safe fixtures or synthetic metadata only.
3. Remove unsafe media, binaries, credentials, or overclaims.
4. Add or update validation checks where feasible.
5. Document the fix without exposing sensitive details.
