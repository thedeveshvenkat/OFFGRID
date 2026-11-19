import Foundation

nonisolated enum BuildConfiguration: Sendable {
    case debug
    case release

    static var current: BuildConfiguration {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
}

nonisolated enum TrackProviderKind: Equatable, Sendable {
    case mock
    case unconfigured
}

/// The single place the app chooses its track source
/// (mock-data-policy rule 4). Debug builds use the mock provider; Release
/// builds can never select it, and the mock code is not compiled into them.
nonisolated enum ProviderSelection {
    static func kind(for configuration: BuildConfiguration) -> TrackProviderKind {
        switch configuration {
        case .debug: return .mock
        case .release: return .unconfigured
        }
    }
}

/// Dependencies the app hands to its features. This is the only production
/// file allowed to reference mock types, and only inside `#if DEBUG`.
nonisolated struct AppEnvironment: Sendable {
    let trackProvider: any TrackProvider

    static func make(configuration: BuildConfiguration = .current) -> AppEnvironment {
        switch ProviderSelection.kind(for: configuration) {
        case .mock:
            #if DEBUG
            return AppEnvironment(trackProvider: MockTrackProvider())
            #else
            return AppEnvironment(trackProvider: UnconfiguredTrackProvider())
            #endif
        case .unconfigured:
            return AppEnvironment(trackProvider: UnconfiguredTrackProvider())
        }
    }
}
