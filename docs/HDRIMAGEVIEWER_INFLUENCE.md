# HDRImageViewer Influence and Boundary

## What to learn

- HDRImageViewer's WinUI 3 shell and D3D11 HDR renderer are the right class of architecture.
- Its FP16 scRGB swap-chain strategy is relevant to video presentation.
- Its format support matrix and diagnostic wording are worth emulating.
- Its license and third-party tool boundary discipline should be preserved.

## What not to do

- Do not copy code without GPL handling.
- Do not present static-image HDR support as video playback support.
- Do not assume gain-map image reconstruction solves Dolby Vision video dynamic metadata.
- Do not claim Dolby Vision because a system media surface plays a file.

## Clean-room implementation rule

Use HDRImageViewer as architectural inspiration. If implementation code is copied, document:

- source file;
- license;
- modifications;
- attribution;
- why copying was necessary.
