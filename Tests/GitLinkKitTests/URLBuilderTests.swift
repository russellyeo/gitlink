import Testing
@testable import GitLinkKit

@Suite struct URLBuilderTests {

    // MARK: - GitHub directory URLs

    @Test func buildURL_forDirectory_usesTreePath() throws {
        // GIVEN a GitHub remote with directory components
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let ref = "main"
        let target = Target.path(ParsedInput(path: "Sources/App", lineSpec: nil))

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: ref, target: target, isDirectory: true)

        // THEN the URL uses tree/
        #expect(url == "https://github.com/depop/my-app/tree/main/Sources/App")
    }

    // MARK: - GitHub file URLs (no lines)

    @Test func buildURL_forFile_usesBlobPath() throws {
        // GIVEN a GitHub remote with file components
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let ref = "feature/search"
        let target = Target.path(ParsedInput(path: "Sources/App/main.swift", lineSpec: nil))

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: ref, target: target, isDirectory: false)

        // THEN the URL uses blob/ with no fragment
        #expect(url == "https://github.com/depop/my-app/blob/feature/search/Sources/App/main.swift")
    }

    // MARK: - GitHub file URLs with single line

    @Test func buildURL_forFileWithSingleLine_appendsLineFragment() throws {
        // GIVEN a GitHub remote with a single line spec
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let lineSpec = LineSpec.single(12)
        let target = Target.path(ParsedInput(path: "Sources/App/main.swift", lineSpec: lineSpec))

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", target: target, isDirectory: false)

        // THEN the URL includes the line fragment
        #expect(url == "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L12")
    }

    // MARK: - GitHub file URLs with line range

    @Test func buildURL_forFileWithLineRange_appendsRangeFragment() throws {
        // GIVEN a GitHub remote with a line range
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let lineSpec = LineSpec.range(start: 12, end: 20)
        let target = Target.path(ParsedInput(path: "Sources/App/main.swift", lineSpec: lineSpec))

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", target: target, isDirectory: false)

        // THEN the URL includes the range fragment
        #expect(url == "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L12-L20")
    }

    // MARK: - Commit hash as ref

    @Test func buildURL_withCommitHash_usesHashAsRef() throws {
        // GIVEN a full commit hash as ref
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let ref = "4f2d8d5a6f0d5f8d7c1234567890abcdef123456"
        let lineSpec = LineSpec.range(start: 12, end: 20)
        let target = Target.path(ParsedInput(path: "Sources/App/main.swift", lineSpec: lineSpec))

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: ref, target: target, isDirectory: false)

        // THEN the commit hash is used as the ref
        #expect(url == "https://github.com/depop/my-app/blob/4f2d8d5a6f0d5f8d7c1234567890abcdef123456/Sources/App/main.swift#L12-L20")
    }

    // MARK: - Special characters in path

    @Test func buildURL_withSpacesInPath_percentEncodesSpaces() throws {
        // GIVEN a path containing spaces
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let target = Target.path(ParsedInput(path: "Sources/My App/main.swift", lineSpec: nil))

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", target: target, isDirectory: false)

        // THEN spaces are percent-encoded per RFC 3986
        #expect(url == "https://github.com/depop/my-app/blob/main/Sources/My%20App/main.swift")
    }

    // MARK: - GitHub commit URLs

    @Test func buildURL_forCommitTarget_producesCommitURL() throws {
        // GIVEN a GitHub remote and a commit target
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let target = Target.commit("abc123def456")

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "abc123def456", target: target, isDirectory: nil)

        // THEN the URL points to the commit page
        #expect(url == "https://github.com/depop/my-app/commit/abc123def456")
    }

    // MARK: - GitHub repo root URLs

    @Test func buildURL_forRepoRootTarget_producesTreeURL() throws {
        // GIVEN a GitHub remote and a repo root target
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let target = Target.repoRoot

        // WHEN we build the URL
        let url = try URLBuilder.buildURL(remote: remote, ref: "main", target: target, isDirectory: nil)

        // THEN the URL points to the repo tree on the branch
        #expect(url == "https://github.com/depop/my-app/tree/main")
    }

    @Test func buildURL_forRepoRootWithBranch_includesBranch() throws {
        // GIVEN a GitHub remote and a repo root target with a feature branch
        let remote = GitRemote(provider: .gitHub, owner: "depop", repo: "my-app")
        let target = Target.repoRoot

        // WHEN we build the URL with a specific branch
        let url = try URLBuilder.buildURL(remote: remote, ref: "feature/search", target: target, isDirectory: nil)

        // THEN the URL includes the branch
        #expect(url == "https://github.com/depop/my-app/tree/feature/search")
    }

    // MARK: - Unsupported providers

    @Test func buildURL_withGitLab_throwsProviderNotSupported() {
        // GIVEN a GitLab remote
        let remote = GitRemote(provider: .gitLab, owner: "depop", repo: "my-app")
        let target = Target.path(ParsedInput(path: "README.md", lineSpec: nil))

        // WHEN we build the URL
        // THEN it throws providerNotSupported
        #expect(throws: GitLinkError.providerNotSupported(provider: "GitLab", issueURL: GitRemoteParser.issueURL)) {
            try URLBuilder.buildURL(remote: remote, ref: "main", target: target, isDirectory: false)
        }
    }

    @Test func buildURL_withBitbucket_throwsProviderNotSupported() {
        // GIVEN a Bitbucket remote
        let remote = GitRemote(provider: .bitbucket, owner: "depop", repo: "my-app")
        let target = Target.path(ParsedInput(path: "README.md", lineSpec: nil))

        // WHEN we build the URL
        // THEN it throws providerNotSupported
        #expect(throws: GitLinkError.providerNotSupported(provider: "Bitbucket", issueURL: GitRemoteParser.issueURL)) {
            try URLBuilder.buildURL(remote: remote, ref: "main", target: target, isDirectory: false)
        }
    }
}
