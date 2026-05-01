public enum OutputFormat: String, CaseIterable, Sendable {
    case url
    case markdown
}

public enum OutputFormatter {

    public static func format(
        result: LinkGenerator.Result,
        format: OutputFormat
    ) -> String {
        switch format {
        case .url:
            return result.url
        case .markdown:
            let title = markdownTitle(result: result)
            return "[\(title)](\(result.url))"
        }
    }

    private static func markdownTitle(result: LinkGenerator.Result) -> String {
        switch result.target {
        case .commit(let hash):
            return "\(result.repoName)/\(hash)"

        case .repoRoot:
            return "\(result.repoName)/\(result.ref)"

        case .path(let parsed):
            guard let lineSpec = parsed.lineSpec else { return parsed.path }
            switch lineSpec {
            case .single(let line):
                return "\(parsed.path)#L\(line)"
            case .range(let start, let end):
                return "\(parsed.path)#L\(start)-L\(end)"
            }
        }
    }
}
