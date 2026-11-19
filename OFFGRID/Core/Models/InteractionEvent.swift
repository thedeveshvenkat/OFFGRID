import Foundation

/// One listener action or listening measurement, as the recommender will
/// receive it. Taste is learned from these, never from forms (principle 2).
nonisolated struct InteractionEvent: Hashable, Codable, Sendable {
    nonisolated enum Kind: Hashable, Codable, Sendable {
        case like
        case next
        case previous
        case notInterested
        case pause
        case resume
        /// How long the listener stayed on the track, in milliseconds.
        case listened(milliseconds: Int)
    }

    let trackID: TrackID
    let kind: Kind
    let occurredAt: Date
}
