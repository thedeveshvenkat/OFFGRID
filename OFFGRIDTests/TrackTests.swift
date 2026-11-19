import Foundation
import Testing
@testable import OFFGRID

struct SnippetTests {
    @Test(arguments: [20.0, 24.0, 30.0])
    func acceptsDurationsInsideTwentyToThirtySeconds(duration: TimeInterval) throws {
        let snippet = try Snippet(start: 12, duration: duration)
        #expect(snippet.duration == duration)
        #expect(snippet.end == 12 + duration)
    }

    @Test(arguments: [0.0, 19.99, 30.01, 90.0, .infinity, .nan])
    func rejectsDurationsOutsideRange(duration: TimeInterval) {
        #expect(throws: Snippet.ValidationError.self) {
            try Snippet(start: 0, duration: duration)
        }
    }

    @Test func rejectsNegativeStart() {
        #expect(throws: Snippet.ValidationError.negativeStart) {
            try Snippet(start: -1, duration: 24)
        }
    }

    @Test func decodingAppliesTheSameValidation() throws {
        let invalid = Data(#"{"start": 0, "duration": 45}"#.utf8)
        #expect(throws: Snippet.ValidationError.durationOutOfRange(45)) {
            try JSONDecoder().decode(Snippet.self, from: invalid)
        }
        let valid = Data(#"{"start": 5, "duration": 25}"#.utf8)
        let decoded = try JSONDecoder().decode(Snippet.self, from: valid)
        #expect(decoded == (try Snippet(start: 5, duration: 25)))
    }
}

struct InteractionEventTests {
    @Test func roundTripsThroughJSON() throws {
        let events = [
            InteractionEvent(trackID: TrackID("t1"), kind: .like, occurredAt: Date(timeIntervalSince1970: 1)),
            InteractionEvent(trackID: TrackID("t1"), kind: .listened(milliseconds: 23_500),
                             occurredAt: Date(timeIntervalSince1970: 2)),
            InteractionEvent(trackID: TrackID("t2"), kind: .notInterested, occurredAt: Date(timeIntervalSince1970: 3)),
        ]
        let decoded = try JSONDecoder().decode([InteractionEvent].self, from: JSONEncoder().encode(events))
        #expect(decoded == events)
    }
}
