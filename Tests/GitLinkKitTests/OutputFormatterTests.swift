import XCTest
@testable import GitLinkKit

final class OutputFormatterTests: XCTestCase {

    // MARK: - URL format

    func test_format_urlFormat_returnsURLUnchanged() {
        // GIVEN a URL and the url format
        let url = "https://github.com/depop/my-app/blob/main/main.swift"
        let target = Target.path(ParsedInput(path: "main.swift", lineSpec: nil))
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "main")

        // WHEN we format the output
        let formatted = OutputFormatter.format(result: result, format: .url)

        // THEN it returns the URL as-is
        XCTAssertEqual(formatted, url)
    }

    // MARK: - Markdown format

    func test_format_markdownWithNoLineSpec_usesPathAsTitle() {
        // GIVEN a URL with no line spec
        let url = "https://github.com/depop/my-app/blob/main/Sources/App/main.swift"
        let target = Target.path(ParsedInput(path: "Sources/App/main.swift", lineSpec: nil))
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "main")

        // WHEN we format as markdown
        let formatted = OutputFormatter.format(result: result, format: .markdown)

        // THEN the title is the path
        XCTAssertEqual(formatted, "[Sources/App/main.swift](https://github.com/depop/my-app/blob/main/Sources/App/main.swift)")
    }

    func test_format_markdownWithSingleLine_includesLineInTitle() {
        // GIVEN a URL with a single line spec
        let url = "https://github.com/depop/my-app/blob/main/main.swift#L12"
        let lineSpec = LineSpec.single(12)
        let target = Target.path(ParsedInput(path: "main.swift", lineSpec: lineSpec))
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "main")

        // WHEN we format as markdown
        let formatted = OutputFormatter.format(result: result, format: .markdown)

        // THEN the title includes the line reference
        XCTAssertEqual(formatted, "[main.swift#L12](https://github.com/depop/my-app/blob/main/main.swift#L12)")
    }

    func test_format_markdownWithLineRange_includesRangeInTitle() {
        // GIVEN a URL with a line range
        let url = "https://github.com/depop/my-app/blob/main/main.swift#L12-L20"
        let lineSpec = LineSpec.range(start: 12, end: 20)
        let target = Target.path(ParsedInput(path: "main.swift", lineSpec: lineSpec))
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "main")

        // WHEN we format as markdown
        let formatted = OutputFormatter.format(result: result, format: .markdown)

        // THEN the title includes the line range
        XCTAssertEqual(formatted, "[main.swift#L12-L20](https://github.com/depop/my-app/blob/main/main.swift#L12-L20)")
    }

    // MARK: - Commit markdown format

    func test_format_markdownForCommitTarget_usesRepoSlashHash() {
        // GIVEN a commit target URL
        let url = "https://github.com/depop/my-app/commit/abc123def456"
        let target = Target.commit("abc123def456")
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "abc123def456")

        // WHEN we format as markdown
        let formatted = OutputFormatter.format(result: result, format: .markdown)

        // THEN the title is repo/hash
        XCTAssertEqual(formatted, "[my-app/abc123def456](https://github.com/depop/my-app/commit/abc123def456)")
    }

    // MARK: - Repo root markdown format

    func test_format_markdownForRepoRootTarget_usesRepoSlashBranch() {
        // GIVEN a repo root target URL
        let url = "https://github.com/depop/my-app/tree/main"
        let target = Target.repoRoot
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "main")

        // WHEN we format as markdown
        let formatted = OutputFormatter.format(result: result, format: .markdown)

        // THEN the title is repo/branch
        XCTAssertEqual(formatted, "[my-app/main](https://github.com/depop/my-app/tree/main)")
    }

    func test_format_markdownForRepoRootWithFeatureBranch_usesRepoSlashBranch() {
        // GIVEN a repo root target URL on a feature branch
        let url = "https://github.com/depop/my-app/tree/feature/search"
        let target = Target.repoRoot
        let result = LinkGenerator.GeneratedLink(url: url, target: target, repoName: "my-app", ref: "feature/search")

        // WHEN we format as markdown
        let formatted = OutputFormatter.format(result: result, format: .markdown)

        // THEN the title is repo/branch
        XCTAssertEqual(formatted, "[my-app/feature/search](https://github.com/depop/my-app/tree/feature/search)")
    }
}
