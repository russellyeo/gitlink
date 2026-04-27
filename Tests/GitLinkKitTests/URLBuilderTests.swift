import XCTest
@testable import GitLinkKit

final class URLBuilderTests: XCTestCase {

    // MARK: - GitHub directory URLs

    func test_buildURL_forDirectory_usesTreePath() throws {
        // GIVEN a GitHub remote with directory components
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let ref = "main"
        let path = "Sources/App"

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: ref, path: path, isDirectory: true, lineSpec: nil)

        // THEN the URL uses tree/
        XCTAssertEqual(url, "https://github.com/depop/my-app/tree/main/Sources/App")
    }

    // MARK: - GitHub file URLs (no lines)

    func test_buildURL_forFile_usesBlobPath() throws {
        // GIVEN a GitHub remote with file components
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let ref = "feature/search"
        let path = "Sources/App/main.swift"

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: ref, path: path, isDirectory: false, lineSpec: nil)

        // THEN the URL uses blob/ with no fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/feature/search/Sources/App/main.swift")
    }

    // MARK: - GitHub file URLs with single line

    func test_buildURL_forFileWithSingleLine_appendsLineFragment() throws {
        // GIVEN a GitHub remote with a single line spec
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let lineSpec = LineSpec.single(12)

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", path: "Sources/App/main.swift", isDirectory: false, lineSpec: lineSpec)

        // THEN the URL includes the line fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L12")
    }

    // MARK: - GitHub file URLs with line range

    func test_buildURL_forFileWithLineRange_appendsRangeFragment() throws {
        // GIVEN a GitHub remote with a line range
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let lineSpec = LineSpec.range(start: 12, end: 20)

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", path: "Sources/App/main.swift", isDirectory: false, lineSpec: lineSpec)

        // THEN the URL includes the range fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L12-L20")
    }

    // MARK: - Commit hash as ref

    func test_buildURL_withCommitHash_usesHashAsRef() throws {
        // GIVEN a full commit hash as ref
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let ref = "4f2d8d5a6f0d5f8d7c1234567890abcdef123456"
        let lineSpec = LineSpec.range(start: 12, end: 20)

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: ref, path: "Sources/App/main.swift", isDirectory: false, lineSpec: lineSpec)

        // THEN the commit hash is used as the ref
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/4f2d8d5a6f0d5f8d7c1234567890abcdef123456/Sources/App/main.swift#L12-L20")
    }

    // MARK: - Special characters in path

    func test_buildURL_withSpacesInPath_percentEncodesSpaces() throws {
        // GIVEN a path containing spaces
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", path: "Sources/My App/main.swift", isDirectory: false, lineSpec: nil)

        // THEN spaces are percent-encoded per RFC 3986
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/My%20App/main.swift")
    }

    // MARK: - Unsupported providers

    func test_buildURL_withGitLab_throwsProviderNotSupported() {
        // GIVEN a GitLab remote
        let remote = GitRemote(provider: .gitLab, owner: "depop", repo: "my-app")

        // WHEN we build the URL
        // THEN it throws providerNotSupported
        XCTAssertThrowsError(try URLBuilder.buildURL(remote: remote, ref: "main", path: "README.md", isDirectory: false, lineSpec: nil)) { error in
            XCTAssertEqual(error as? GitLinkError, .providerNotSupported(provider: "GitLab", issueURL: GitRemoteParser.issueURL))
        }
    }

    func test_buildURL_withBitbucket_throwsProviderNotSupported() {
        // GIVEN a Bitbucket remote
        let remote = GitRemote(provider: .bitbucket, owner: "depop", repo: "my-app")

        // WHEN we build the URL
        // THEN it throws providerNotSupported
        XCTAssertThrowsError(try URLBuilder.buildURL(remote: remote, ref: "main", path: "README.md", isDirectory: false, lineSpec: nil)) { error in
            XCTAssertEqual(error as? GitLinkError, .providerNotSupported(provider: "Bitbucket", issueURL: GitRemoteParser.issueURL))
        }
    }
}
