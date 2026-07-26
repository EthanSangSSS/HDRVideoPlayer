import AppKit
import Foundation

public struct MacDisplayDiagnostic: Equatable, Sendable {
    public var screenName: String?
    public var maximumCurrentEDRColorComponentValue: Double?
    public var maximumPotentialEDRColorComponentValue: Double?
    public var maximumReferenceEDRColorComponentValue: Double?
    public var supportsEDR: Bool
    public var hasCurrentEDRHeadroom: Bool
    public var limitation: String

    public init(
        screenName: String?,
        maximumCurrentEDRColorComponentValue: Double?,
        maximumPotentialEDRColorComponentValue: Double? = nil,
        maximumReferenceEDRColorComponentValue: Double? = nil,
        limitation: String = "Display support derives only from potential EDR capability; current headroom and reference EDR are independent facts. Missing values produce no positive inference, and these facts do not prove HDR or Dolby Vision video presentation accuracy."
    ) {
        self.screenName = screenName
        self.maximumCurrentEDRColorComponentValue = maximumCurrentEDRColorComponentValue
        self.maximumPotentialEDRColorComponentValue = maximumPotentialEDRColorComponentValue
        self.maximumReferenceEDRColorComponentValue = maximumReferenceEDRColorComponentValue
        self.supportsEDR = (maximumPotentialEDRColorComponentValue ?? 1.0) > 1.0
        self.hasCurrentEDRHeadroom = (maximumCurrentEDRColorComponentValue ?? 1.0) > 1.0
        self.limitation = limitation
    }

    public static let unavailable = MacDisplayDiagnostic(
        screenName: nil,
        maximumCurrentEDRColorComponentValue: nil
    )
}

@MainActor
public enum MacDisplayDiagnostics {
    public static func current(screen: NSScreen? = NSScreen.main) -> MacDisplayDiagnostic {
        guard let screen else {
            return .unavailable
        }

        let screenName = screen.localizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return MacDisplayDiagnostic(
            screenName: screenName.isEmpty ? nil : screenName,
            maximumCurrentEDRColorComponentValue: Double(
                screen.maximumExtendedDynamicRangeColorComponentValue
            ),
            maximumPotentialEDRColorComponentValue: Double(
                screen.maximumPotentialExtendedDynamicRangeColorComponentValue
            ),
            maximumReferenceEDRColorComponentValue: Double(
                screen.maximumReferenceExtendedDynamicRangeColorComponentValue
            )
        )
    }
}
