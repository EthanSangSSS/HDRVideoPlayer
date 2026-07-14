import Foundation

public enum MacSystemPlaybackState: String, Equatable, Sendable {
    case idle
    case loading
    case ready
    case failed
}

public extension MacMediaAsset {
    func withSystemPlaybackState(_ state: MacSystemPlaybackState) -> MacMediaAsset {
        var copy = self
        copy.systemPlaybackState = state

        if state != .idle {
            copy.presentationClaim = .systemPreview
        }

        return copy
    }
}
