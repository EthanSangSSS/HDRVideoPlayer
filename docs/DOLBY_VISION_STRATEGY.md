# Dolby Vision Strategy

## Principle

Dolby Vision support must be staged and profile-specific. Detection is not rendering. Fallback playback is not full Dolby Vision. Certification is out of scope unless explicitly licensed.

## Capability ladder

1. `detect_only`
2. `fallback_playback`
3. `experimental_rendering`
4. `validated_rendering`
5. `certified` — not a public goal

## Stage 0 — Detection

Detect:

- Dolby Vision marker presence;
- profile candidate;
- level candidate;
- base-layer compatibility;
- RPU presence if accessible.

Allowed wording:

- “Dolby Vision markers detected.”
- “Profile candidate: 8.1.”
- “Dynamic metadata application: not implemented.”

## Stage 1 — Profile 8.1 fallback

Profile 8.1 is the early practical target because the base layer is commonly HDR10-compatible.

Allowed wording after validation:

- “Profile 8.1 file played through HDR10-compatible base-layer fallback.”
- “Dolby Vision dynamic metadata is detected but not applied.”

## Stage 2 — Profile 5 detection / unsupported rendering

Profile 5 should be detect-only until a lawful and technically valid processing path exists.

## Stage 3 — Profile 7 detection / unsupported enhancement layer

Profile 7 should initially be classification only. Do not claim FEL/MEL enhancement reconstruction.

## Stage 4 — Experimental dynamic metadata path

Only after:

- lawful parser path exists;
- sample corpus is licensed;
- shader pipeline supports metadata-driven transforms;
- validation matrix has expected outputs.
