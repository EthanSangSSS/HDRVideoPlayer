# Legal and Codec Boundary

## GPL boundary

HDRImageViewer is GPLv3-or-later. If this project copies or adapts code from it, this repository must remain GPL-compatible and preserve attribution.

This scaffold uses a GPL-compatible posture until a dedicated license review proves clean-room independence.

## Dolby boundary

Do not:

- claim Dolby Vision certification;
- distribute proprietary Dolby SDKs;
- bypass DRM;
- ship unlicensed samples;
- claim Profile 5 / 7 correctness without proof.

Allowed:

- detect public/container markers;
- document profile candidates;
- play HDR10-compatible fallback layers where legal and technically valid;
- clearly label limitations.

## Codec boundary

Do not bundle binary codec stacks until reviewed:

- FFmpeg build configuration;
- LGPL/GPL implications;
- libplacebo;
- x265 / HEVC patent exposure;
- AV1;
- Dolby Vision metadata libraries;
- Microsoft Store distribution constraints.

## Sample media boundary

Allowed sample inputs:

- generated test patterns;
- public-domain samples;
- explicitly licensed samples;
- user-local media excluded from git.

Forbidden:

- commercial movie clips;
- DRM-protected media;
- downloaded copyrighted snippets.
