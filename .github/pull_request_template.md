## Summary

## Validation

- [ ] `dotnet restore .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj`
- [ ] `dotnet build .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug`
- [ ] `dotnet test .\tests\HDRVideoPlayer.Core.Tests\HDRVideoPlayer.Core.Tests.csproj -c Debug`
- [ ] `.\scripts\public-safety-scan.ps1`
- [ ] `git diff --check`

## Risk checklist

- Playback behavior changed: yes/no
- Metadata detection changed: yes/no
- Renderer path changed: yes/no
- Licensing surface changed: yes/no
- Bundled binaries added: yes/no
- Sample media added: yes/no
- Dolby Vision claim changed: yes/no

## Boundaries

- [ ] No DRM circumvention.
- [ ] No Dolby certification claim.
- [ ] No bundled codec binaries without review.
- [ ] No committed commercial sample media.
