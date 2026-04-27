import XCTest
@testable import GitLinkKit

final class OutputFormatterTests: XCTestCase {

    // MARK: - URL format

    func test_format_urlFormat_returnsURLUnchanged() {
        // GIVEN a URL and the url format
        let url = "https://github.com/depop/my-app/blob/main/main.swift"
        let format = OutputFormat.url

        // WHEN we format the output
        let result = OutputFormatter.format(url: url, path: "main.swift", lineSpec: nil, format: format)

        // THEN it returns the URL as-is
        XCTAssertEqual(result, url)
    }

    // MARK: - Markdown format

    func test_format_markdownWithNoLineSpec_usesPathAsTitle() {
        // GIVEN a URL with no line spec
        let url = "https://github.com/depop/my-app/blob/main/Sources/App/main.swift"
        let path = "Sources/App/main.swift"

        // WHEN we format as markdown
        let result = OutputFormatter.format(url: url, path: path, lineSpec: nil, format: .markdown)

        // THEN the title is the path
        XCTAssertEqual(result, "[Sources/App/main.swift](https://github.com/depop/my-app/blob/main/Sources/App/main.swift)")
    }

    func test_format_markdownWithSingleLine_includesLineInTitle() {
        // GIVEN a URL with a single line spec
        let url = "https://github.com/depop/my-app/blob/main/main.swift#L12"
        let path = "main.swift"
        let lineSpec = LineSpec.single(12)

        // WHEN we format as markdown
        let result = OutputFormatter.format(url: url, path: path, lineSpec: lineSpec, format: .markdown)

        // THEN the title includes the line reference
        XCTAssertEqual(result, "[main.swift#L12](https://github.com/depop/my-app/blob/main/main.swift#L12)")
    }

    func test_format_markdownWithLineRange_includesRangeInTitle() {
        // GIVEN a URL with a line range
        let url = "https://github.com/depop/my-app/blob/main/main.swift#L12-L20"
        let path = "main.swift"
        let lineSpec = LineSpec.range(start: 12, end: 20)

        // WHEN we format as markdown
        let result = OutputFormatter.format(url: url, path: path, lineSpec: lineSpec, format: .markdown)

        // THEN the title includes the line range
        XCTAssertEqual(result, "[main.swift#L12-L20](https://github.com/depop/my-app/blob/main/main.swift#L12-L20)")
    }
}
