// URLBuilderTests.swift
// GHLinkKit
// 2026-04-27 — Russell Yeo

import XCTest
@testable import GHLinkKit

final class URLBuilderTests: XCTestCase {

    // MARK: - Directory URLs

    func test_buildURL_forDirectory_usesTreePath() {
        // GIVEN directory components
        let owner = "depop"
        let repo = "my-app"
        let ref = "main"
        let path = "Sources/App"

        // WHEN we build the URL
        let url = URLBuilder.buildURL(
            owner: owner,
            repo: repo,
            ref: ref,
            path: path,
            isDirectory: true,
            lineSpec: nil
        )

        // THEN the URL uses tree/
        XCTAssertEqual(url, "https://github.com/depop/my-app/tree/main/Sources/App")
    }

    // MARK: - File URLs (no lines)

    func test_buildURL_forFile_usesBlobPath() {
        // GIVEN file components with no line spec
        let owner = "depop"
        let repo = "my-app"
        let ref = "feature/search"
        let path = "Sources/App/main.swift"

        // WHEN we build the URL
        let url = URLBuilder.buildURL(
            owner: owner,
            repo: repo,
            ref: ref,
            path: path,
            isDirectory: false,
            lineSpec: nil
        )

        // THEN the URL uses blob/ with no fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/feature/search/Sources/App/main.swift")
    }

    // MARK: - File URLs with single line

    func test_buildURL_forFileWithSingleLine_appendsLineFragment() {
        // GIVEN file components with a single line
        let owner = "depop"
        let repo = "my-app"
        let ref = "main"
        let path = "Sources/App/main.swift"
        let lineSpec = LineSpec.single(12)

        // WHEN we build the URL
        let url = URLBuilder.buildURL(
            owner: owner,
            repo: repo,
            ref: ref,
            path: path,
            isDirectory: false,
            lineSpec: lineSpec
        )

        // THEN the URL includes the line fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L12")
    }

    // MARK: - File URLs with line range

    func test_buildURL_forFileWithLineRange_appendsRangeFragment() {
        // GIVEN file components with a line range
        let owner = "depop"
        let repo = "my-app"
        let ref = "main"
        let path = "Sources/App/main.swift"
        let lineSpec = LineSpec.range(start: 12, end: 20)

        // WHEN we build the URL
        let url = URLBuilder.buildURL(
            owner: owner,
            repo: repo,
            ref: ref,
            path: path,
            isDirectory: false,
            lineSpec: lineSpec
        )

        // THEN the URL includes the range fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L12-L20")
    }

    // MARK: - Commit hash as ref

    func test_buildURL_withCommitHash_usesHashAsRef() {
        // GIVEN a full commit hash as ref
        let owner = "depop"
        let repo = "my-app"
        let ref = "4f2d8d5a6f0d5f8d7c1234567890abcdef123456"
        let path = "Sources/App/main.swift"
        let lineSpec = LineSpec.range(start: 12, end: 20)

        // WHEN we build the URL
        let url = URLBuilder.buildURL(
            owner: owner,
            repo: repo,
            ref: ref,
            path: path,
            isDirectory: false,
            lineSpec: lineSpec
        )

        // THEN the commit hash is used as the ref
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/4f2d8d5a6f0d5f8d7c1234567890abcdef123456/Sources/App/main.swift#L12-L20")
    }

    // MARK: - Special characters in path

    func test_buildURL_withSpacesInPath_preservesSpaces() {
        // GIVEN a path containing spaces
        let owner = "depop"
        let repo = "my-app"
        let ref = "main"
        let path = "Sources/My App/main.swift"

        // WHEN we build the URL
        let url = URLBuilder.buildURL(
            owner: owner,
            repo: repo,
            ref: ref,
            path: path,
            isDirectory: false,
            lineSpec: nil
        )

        // THEN spaces are preserved (GitHub handles encoding)
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/My App/main.swift")
    }
}
