# macOS Metal EDR Test Pattern

## Scope

`HDRVideoPlayerMacEDRPattern` is an isolated static-pixel experiment. It does not open media, receive decoded frames, use AVPlayer, import VideoToolbox, apply HDR video transfer functions, or process Dolby Vision metadata.

The renderer submits eight fixed extended-linear-sRGB bands to an `rgba16Float` Metal drawable. Component values are `0.00`, `0.18`, `1.00`, `2.00`, and `4.00`, plus red, green, and blue bands at `2.00`. Values above `1.0` prove only what was submitted to the FP16 target.

## Run

```bash
swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacEDRPattern
```

The diagnostics pane records these evidence layers separately:

- renderer configuration and maximum submitted component;
- current, potential, and reference EDR component values exposed by `NSScreen`;
- unknowns and limitations;
- presentation path and accuracy claim.

The presentation claim remains `unverified`.

## Automated validation

```bash
swift build --package-path macos/HDRVideoPlayerMac -Xswiftc -warnings-as-errors
swift test --package-path macos/HDRVideoPlayerMac -Xswiftc -warnings-as-errors
```

The Metal tests verify the MTKView layer configuration and render the same shader into a shared `rgba16Float` texture. Center pixels from every band are read back and compared with the configured FP16 values. This validates software configuration and GPU submission, not visible luminance.

## Display observation procedure

Use an intended, locally authorized display setup. Record observations outside the repository until the result is sanitized.

1. Put the app window entirely on the display under test and refresh diagnostics.
2. Record screen identity plus current, potential, and reference EDR component values.
3. Record whether the `2.00` and `4.00` white bands are visibly distinct from `1.00`, clipped together, or indeterminate.
4. Record whether the three `2.00` primary-color bands remain distinguishable; do not describe them as accurate without measurement.
5. If a calibrated meter is available, record the measurement method and luminance separately. A visual observation alone is not a measurement.
6. Keep presentation accuracy `unknown / unverified` unless a repeatable measurement protocol and result justify a narrower statement.

## Claim boundary

- A Metal command completing proves only that the GPU accepted the static render work.
- FP16 readback values above `1.0` do not prove that a display emitted EDR luminance.
- `wantsExtendedDynamicRangeContent` requests EDR composition; it does not guarantee current headroom.
- No result from this executable proves HDR10, HLG, or Dolby Vision video presentation.
- No Dolby Vision certification or full-playback claim is made.

## Public API basis

The layer configuration follows Apple's documented EDR path: an `rgba16Float` Metal layer, an extended linear color space, and `wantsExtendedDynamicRangeContent`. `NSScreen.maximumExtendedDynamicRangeColorComponentValue` is treated as a current screen fact that may change with display and system conditions.

- [Performing your own tone mapping](https://developer.apple.com/documentation/metal/performing-your-own-tone-mapping)
- [CAMetalLayer wantsExtendedDynamicRangeContent](https://developer.apple.com/documentation/quartzcore/cametallayer/wantsextendeddynamicrangecontent)
- [NSScreen maximumExtendedDynamicRangeColorComponentValue](https://developer.apple.com/documentation/appkit/nsscreen/maximumextendeddynamicrangecolorcomponentvalue)
