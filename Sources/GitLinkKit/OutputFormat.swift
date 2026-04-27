public enum OutputFormat: String, CaseIterable, Sendable {
    case url
    case markdown
}

public enum OutputFormatter {

    public static func format(
        url: String,
        path: String,
        lineSpec: LineSpec?,
        format: OutputFormat
    ) -> String {
        switch format {
        case .url:
            return url
        case .markdown:
            let title = markdownTitle(path: path, lineSpec: lineSpec)
            return "[\(title)](\(url))"
        }
    }

    private static func markdownTitle(path: String, lineSpec: LineSpec?) -> String {
        guard let lineSpec else { return path }
        switch lineSpec {
        case .single(let line):
            return "\(path)#L\(line)"
        case .range(let start, let end):
            return "\(path)#L\(start)-L\(end)"
        }
    }
}
