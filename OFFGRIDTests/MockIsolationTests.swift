import Foundation
import Testing

/// Enforces the mock-data policy in source code: production code outside
/// `OFFGRID/Mocks/` may not reference any mock type, except `AppEnvironment`,
/// and that only inside `#if DEBUG`. Comments and string literals are ignored,
/// so documentation that mentions a type does not fail the check.
struct MockIsolationTests {
    static let appSourceRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()      // OFFGRIDTests/
        .deletingLastPathComponent()      // repo root
        .appending(path: "OFFGRID", directoryHint: .isDirectory)
    static let mocksRoot = appSourceRoot.appending(path: "Mocks", directoryHint: .isDirectory)
    static let compositionRoot = appSourceRoot.appending(path: "App/AppEnvironment.swift")

    // MARK: - The policy, applied to the real source tree

    @Test func mockTypesAreDiscovered() throws {
        let names = try Self.mockTypeNames()
        #expect(names.contains("MockTrackProvider"))
        #expect(names.contains("MockCatalog"))
        #expect(names.contains("PlaceholderToneGenerator"))
    }

    @Test func everyMockFileIsCompiledOnlyInDebug() throws {
        let files = try Self.swiftFiles(under: Self.mocksRoot)
        #expect(!files.isEmpty)
        for file in files {
            let code = SourceScanner.codeOnly(try String(contentsOf: file, encoding: .utf8))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(code.hasPrefix("#if DEBUG") && code.hasSuffix("#endif"),
                    "\(file.lastPathComponent) must be wrapped in #if DEBUG … #endif")
        }
    }

    @Test func productionCodeDoesNotReferenceMockTypes() throws {
        let mockNames = try Self.mockTypeNames()
        let production = try Self.swiftFiles(under: Self.appSourceRoot).filter {
            !$0.path.hasPrefix(Self.mocksRoot.path) && $0.standardizedFileURL != Self.compositionRoot.standardizedFileURL
        }
        #expect(!production.isEmpty)
        for file in production {
            let used = SourceScanner.identifiers(in: try String(contentsOf: file, encoding: .utf8))
            #expect(used.isDisjoint(with: mockNames),
                    "\(file.lastPathComponent) references mock types: \(used.intersection(mockNames).sorted())")
        }
    }

    @Test func compositionRootUsesMocksOnlyInsideDebug() throws {
        let source = try String(contentsOf: Self.compositionRoot, encoding: .utf8)
        let violations = SourceScanner.referencesOutsideDebug(in: source, names: try Self.mockTypeNames())
        #expect(violations.isEmpty, "AppEnvironment references mock types outside #if DEBUG: \(violations)")
    }

    // MARK: - The scanner itself catches what it should and ignores what it should

    @Test func scannerFlagsCodeButIgnoresCommentsAndStrings() {
        let names: Set<String> = ["MockTrackProvider"]
        #expect(!SourceScanner.identifiers(in: "let p = MockTrackProvider()").isDisjoint(with: names))
        #expect(SourceScanner.identifiers(in: "// uses MockTrackProvider in Debug").isDisjoint(with: names))
        #expect(SourceScanner.identifiers(in: "/* MockTrackProvider */ let x = 1").isDisjoint(with: names))
        #expect(SourceScanner.identifiers(in: #"let s = "MockTrackProvider""#).isDisjoint(with: names))
    }

    @Test func scannerFlagsReferencesOutsideDebugBranches() {
        let names: Set<String> = ["MockTrackProvider"]
        let inside = "#if DEBUG\nlet p = MockTrackProvider()\n#else\nlet p = Other()\n#endif"
        let inElse = "#if DEBUG\nlet p = Other()\n#else\nlet p = MockTrackProvider()\n#endif"
        let bare = "let p = MockTrackProvider()"
        #expect(SourceScanner.referencesOutsideDebug(in: inside, names: names).isEmpty)
        #expect(SourceScanner.referencesOutsideDebug(in: inElse, names: names) == [4])
        #expect(SourceScanner.referencesOutsideDebug(in: bare, names: names) == [1])
    }

    // MARK: - Helpers

    static func swiftFiles(under root: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        return (enumerator?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
    }

    /// Type names declared in `Mocks/`.
    static func mockTypeNames() throws -> Set<String> {
        let declaration = #/\b(?:struct|class|actor|enum|protocol|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)/#
        var names = Set<String>()
        for file in try swiftFiles(under: mocksRoot) {
            let code = SourceScanner.codeOnly(try String(contentsOf: file, encoding: .utf8))
            for match in code.matches(of: declaration) { names.insert(String(match.1)) }
        }
        return names
    }
}

/// Tiny Swift source scanner: enough to separate code from comments and
/// string literals for the isolation checks above.
enum SourceScanner {
    /// The source with comments and string literal contents replaced by
    /// spaces. Newlines are kept so line numbers stay valid.
    static func codeOnly(_ source: String) -> String {
        let chars = Array(source)
        var out = [Character]()
        out.reserveCapacity(chars.count)
        var i = 0
        func blank(_ c: Character) -> Character { c == "\n" ? "\n" : " " }

        while i < chars.count {
            let c = chars[i]
            let next: Character? = i + 1 < chars.count ? chars[i + 1] : nil
            if c == "/" && next == "/" {                       // line comment
                while i < chars.count && chars[i] != "\n" { out.append(" "); i += 1 }
            } else if c == "/" && next == "*" {                // block comment (nestable)
                var depth = 0
                repeat {
                    if chars[i] == "/" && i + 1 < chars.count && chars[i + 1] == "*" {
                        depth += 1; out += [" ", " "]; i += 2; continue
                    }
                    if chars[i] == "*" && i + 1 < chars.count && chars[i + 1] == "/" {
                        depth -= 1; out += [" ", " "]; i += 2; continue
                    }
                    out.append(blank(chars[i])); i += 1
                } while i < chars.count && depth > 0
            } else if c == "\"" {                              // string literal
                let isMultiline = next == "\"" && i + 2 < chars.count && chars[i + 2] == "\""
                let quoteLength = isMultiline ? 3 : 1
                out += Array(repeating: " ", count: quoteLength); i += quoteLength
                while i < chars.count {
                    if chars[i] == "\\" { out += [" ", " "]; i += 2; continue }
                    if chars[i] == "\"" && (!isMultiline ||
                        (i + 2 < chars.count && chars[i + 1] == "\"" && chars[i + 2] == "\"")) {
                        out += Array(repeating: " ", count: quoteLength); i += quoteLength
                        break
                    }
                    out.append(blank(chars[i])); i += 1
                }
            } else {
                out.append(c); i += 1
            }
        }
        return String(out.prefix(chars.count))
    }

    static func identifiers(in source: String) -> Set<String> {
        Set(codeOnly(source).matches(of: #/[A-Za-z_][A-Za-z0-9_]*/#).map { String($0.output) })
    }

    /// 1-based line numbers where any of `names` is used outside the true
    /// branch of an `#if DEBUG` block.
    static func referencesOutsideDebug(in source: String, names: Set<String>) -> [Int] {
        enum Branch { case debugTrue, debugElse, other }
        var stack: [Branch] = []
        var violations: [Int] = []
        for (offset, line) in codeOnly(source).split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#if") {
                stack.append(trimmed == "#if DEBUG" ? .debugTrue : .other)
            } else if trimmed.hasPrefix("#else") || trimmed.hasPrefix("#elseif") {
                if stack.last == .debugTrue { stack[stack.count - 1] = .debugElse }
            } else if trimmed.hasPrefix("#endif") {
                _ = stack.popLast()
            } else if !identifiers(in: String(line)).isDisjoint(with: names),
                      !stack.contains(.debugTrue) || stack.contains(.debugElse) {
                violations.append(offset + 1)
            }
        }
        return violations
    }
}
