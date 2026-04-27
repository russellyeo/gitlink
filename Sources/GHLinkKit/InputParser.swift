import Foundation

public enum LineSpec: Equatable {
    case single(Int)
    case range(start: Int, end: Int)
}

public struct ParsedInput: Equatable {
    public let path: String
    public let lineSpec: LineSpec?
}

public enum InputParser {

    public static func parse(_ input: String) -> ParsedInput {
        guard let lastColonIndex = input.lastIndex(of: ":") else {
            return ParsedInput(path: input, lineSpec: nil)
        }

        let afterColon = String(input[input.index(after: lastColonIndex)...])
        let beforeColon = String(input[..<lastColonIndex])

        if let lineSpec = parseLineSpec(afterColon) {
            return ParsedInput(path: beforeColon, lineSpec: lineSpec)
        }

        return ParsedInput(path: input, lineSpec: nil)
    }

    public static func validateLineSpec(_ spec: LineSpec) throws {
        switch spec {
        case .single(let line):
            guard line > 0 else {
                throw GHLinkError.invalidLineSpec("\(line)")
            }
        case .range(let start, let end):
            guard start > 0, end > 0 else {
                throw GHLinkError.invalidLineSpec("\(start)-\(end)")
            }
            guard end >= start else {
                throw GHLinkError.invalidLineSpec("\(start)-\(end)")
            }
        }
    }

    private static func parseLineSpec(_ text: String) -> LineSpec? {
        if text.contains("-") {
            let parts = text.split(separator: "-", maxSplits: 1)
            guard parts.count == 2,
                  let start = Int(parts[0]),
                  let end = Int(parts[1]) else {
                return nil
            }
            return .range(start: start, end: end)
        }

        guard let line = Int(text) else {
            return nil
        }
        return .single(line)
    }
}
