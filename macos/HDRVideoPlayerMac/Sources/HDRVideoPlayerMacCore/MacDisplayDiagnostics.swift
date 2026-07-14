import AppKit
import Foundation

public struct MacDisplayDiagnostic: Equatable, Sendable {
    public var screenName: String?
    public var maximumEDRColorComponentValue: Double?
    public var isEDRAvailable: Bool
    public var limitation: String

    public init(
        screenName: String?,
        maximumEDRColorComponentValue: Double?,
        limitation: String = "EDR availability is a display capability fact only. It does not prove HDR or Dolby Vision video presentation accuracy."
    ) {
        self.screenName = screenName
        self.maximumEDRColorComponentValue = maximumEDRColorComponentValue
        self.isEDRAvailable = (maximumEDRColorComponentValue ?? 1.0) > 1.0
        self.limitation = limitation
    }

    public static let unavailable = MacDisplayDiagnostic(
        screenName: nil,
        maximumEDRColorComponentValue: nil
    )
}

@MainActor
public enum MacDisplayDiagnostics {
    public static func current(screen: NSScreen? = NSScreen.main) -> MacDisplayDiagnostic {
        guard let screen else {
            return .unavailable
        }

        return MacDisplayDiagnostic(
            screenName: screen.localizedName,
            maximumEDRColorComponentValue: Double(screen.maximumExtendedDynamicRangeColorComponentValue)
        )
    }
}
