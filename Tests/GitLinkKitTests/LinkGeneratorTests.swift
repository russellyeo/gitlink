import XCTest
@testable import GitLinkKit

final class MockGitService: GitService {
    var remoteURLResult: Result<String, Error> = .success("https://github.com/depop/my-app.git")
    var currentBranchResult: Result<String, Error> = .success("main")
    var repositoryRootResult: Result<String, Error> = .success("/tmp/repo")
    var resolveCommitResult: Result<String, Error> = .success("abc123def456")
    var resolveCommitCalledWith: String?

    func remoteURL() throws -> String {
        try remoteURLResult.get()
    }

    func currentBranch() throws -> String {
        try currentBranchResult.get()
    }

    func repositoryRoot() throws -> String {
        try repositoryRootResult.get()
    }

    func resolveCommit(_ ref: String?) throws -> String {
        resolveCommitCalledWith = ref
        return try resolveCommitResult.get()
    }
}

final class LinkGeneratorTests: XCTestCase {

    private var tempDir: URL!
    private var mockGit: MockGitService!
    private var sut: LinkGenerator!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitLinkGenTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        mockGit = MockGitService()
        mockGit.repositoryRootResult = .success(tempDir.path)
        sut = LinkGenerator(gitService: mockGit)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - File URL with current branch

    func test_generate_fileWithNoOptions_usesCurrentBranch() throws {
        // GIVEN a file exists in the repo
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...20).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        // AND the current branch is "feature/search"
        mockGit.currentBranchResult = .success("feature/search")

        // WHEN we generate a link with no options
        let result = try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the URL uses the current branch
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/feature/search/main.swift")
    }

    // MARK: - File URL with line range

    func test_generate_fileWithLineRange_includesLineFragment() throws {
        // GIVEN a file exists with 20 lines
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...20).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link with a line range
        let result = try sut.generate(
            target: .path(InputParser.parse("main.swift:12-20")),
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the URL includes the line range fragment
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/main/main.swift#L12-L20")
    }

    // MARK: - Directory URL

    func test_generate_directory_usesTreePath() throws {
        // GIVEN a directory exists in the repo
        let dirPath = tempDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)

        // WHEN we generate a link for a directory
        let result = try sut.generate(
            target: .path(InputParser.parse("Sources")),
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the URL uses tree/
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/tree/main/Sources")
    }

    // MARK: - Branch override

    func test_generate_withBranchOverride_usesBranch() throws {
        // GIVEN a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link with a branch override
        let result = try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: "develop"
        )

        // THEN the URL uses the overridden branch
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/develop/main.swift")
    }

    // MARK: - Commit pinning

    func test_generate_withCommitHash_resolvesAndUsesHash() throws {
        // GIVEN a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        // AND the git service resolves "HEAD" to a full hash
        let resolvedHash = "4f2d8d5a6f0d5f8d7c1234567890abcdef123456"
        mockGit.resolveCommitResult = .success(resolvedHash)

        // WHEN we generate a link with a commit ref
        let result = try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: nil,
            commit: "HEAD"
        )

        // THEN the URL uses the resolved commit hash
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/4f2d8d5a6f0d5f8d7c1234567890abcdef123456/main.swift")
        // AND the commit ref was forwarded to the git service
        XCTAssertEqual(mockGit.resolveCommitCalledWith, "HEAD")
    }

    func test_generate_withShortCommitHash_resolvesAndUsesFullHash() throws {
        // GIVEN a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        // AND the git service resolves "abc123" to a full hash
        let resolvedHash = "abc123def456789"
        mockGit.resolveCommitResult = .success(resolvedHash)

        // WHEN we generate a link with a short commit hash
        let result = try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: nil,
            commit: "abc123"
        )

        // THEN the URL uses the resolved full hash
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/abc123def456789/main.swift")
        // AND the short hash was forwarded to the git service
        XCTAssertEqual(mockGit.resolveCommitCalledWith, "abc123")
    }

    // MARK: - Error cases

    func test_generate_nonExistentFile_throwsPathNotFound() {
        // GIVEN a path that doesn't exist
        let expectedPath = tempDir.appendingPathComponent("nope.swift").path

        // WHEN we generate a link
        // THEN it throws pathNotFound
        XCTAssertThrowsError(try sut.generate(
            target: .path(InputParser.parse("nope.swift")),
            workingDirectory: tempDir.path,
            branch: nil
        )) { error in
            XCTAssertEqual(error as? GitLinkError, .pathNotFound(expectedPath))
        }
    }

    func test_generate_linesOnDirectory_throwsError() throws {
        // GIVEN a directory exists
        let dirPath = tempDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)

        // WHEN we generate a link with lines on a directory
        // THEN it throws linesOnDirectory
        XCTAssertThrowsError(try sut.generate(
            target: .path(InputParser.parse("Sources:5")),
            workingDirectory: tempDir.path,
            branch: nil
        )) { error in
            XCTAssertEqual(error as? GitLinkError, .linesOnDirectory)
        }
    }

    func test_generate_lineOutOfRange_throwsError() throws {
        // GIVEN a file with 5 lines
        let filePath = tempDir.appendingPathComponent("short.swift")
        let content = (1...5).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link referencing line 10
        // THEN it throws lineOutOfRange
        XCTAssertThrowsError(try sut.generate(
            target: .path(InputParser.parse("short.swift:10")),
            workingDirectory: tempDir.path,
            branch: nil
        )) { error in
            XCTAssertEqual(error as? GitLinkError, .lineOutOfRange(line: 10, totalLines: 5))
        }
    }

    func test_generate_unsupportedProvider_throwsProviderNotSupported() {
        // GIVEN the remote is a GitLab repository
        mockGit.remoteURLResult = .success("https://gitlab.com/depop/my-app.git")
        // AND a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        try! "line 1".write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link
        // THEN it throws providerNotSupported
        XCTAssertThrowsError(try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: nil
        )) { error in
            XCTAssertEqual(error as? GitLinkError, .providerNotSupported(provider: "GitLab", issueURL: GitRemoteParser.issueURL))
        }
    }

    func test_generate_unknownRemote_throwsUnknownRemote() {
        // GIVEN the remote is an unrecognised host
        let remoteURL = "https://codeberg.org/depop/my-app.git"
        mockGit.remoteURLResult = .success(remoteURL)
        // AND a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        try! "line 1".write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link
        // THEN it throws unknownRemote
        XCTAssertThrowsError(try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: nil
        )) { error in
            XCTAssertEqual(error as? GitLinkError, .unknownRemote(remoteURL))
        }
    }

    // MARK: - Nested file path

    func test_generate_nestedFile_producesCorrectRelativePath() throws {
        // GIVEN a nested file structure
        let nestedDir = tempDir.appendingPathComponent("Sources/App")
        try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
        let filePath = nestedDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link for a nested file
        let result = try sut.generate(
            target: .path(InputParser.parse("Sources/App/main.swift:5")),
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the path is relative to the repo root
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L5")
    }

    // MARK: - SSH remote

    func test_generate_sshRemote_producesCorrectURL() throws {
        // GIVEN the remote uses SSH format
        mockGit.remoteURLResult = .success("git@github.com:depop/my-app.git")
        // AND a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link
        let result = try sut.generate(
            target: .path(InputParser.parse("main.swift")),
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the URL is correct
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/blob/main/main.swift")
    }

    // MARK: - Commit mode (no path)

    func test_generate_commitTargetWithNoPath_producesCommitURL() throws {
        // GIVEN the resolved commit is a full hash
        mockGit.resolveCommitResult = .success("abc123def456789")

        // WHEN we generate a link for a commit target
        let result = try sut.generate(
            target: .commit("abc123"),
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the URL points to the commit page
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/commit/abc123def456789")
        // AND the repo name is captured
        XCTAssertEqual(result.repoName, "my-app")
        // AND the ref is the resolved hash
        XCTAssertEqual(result.ref, "abc123def456789")
        // AND the commit ref was forwarded to the git service
        XCTAssertEqual(mockGit.resolveCommitCalledWith, "abc123")
    }

    // MARK: - Repo root mode

    func test_generate_repoRootTarget_producesTreeURL() throws {
        // GIVEN the current branch is "main"
        mockGit.currentBranchResult = .success("main")

        // WHEN we generate a link for a repo root target
        let result = try sut.generate(
            target: .repoRoot,
            workingDirectory: tempDir.path,
            branch: nil
        )

        // THEN the URL points to the repo tree
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/tree/main")
        // AND the repo name is captured
        XCTAssertEqual(result.repoName, "my-app")
        // AND the ref is the current branch
        XCTAssertEqual(result.ref, "main")
    }

    func test_generate_repoRootWithBranchOverride_usesBranch() throws {
        // WHEN we generate a link for a repo root target with a branch override
        let result = try sut.generate(
            target: .repoRoot,
            workingDirectory: tempDir.path,
            branch: "develop"
        )

        // THEN the URL includes the overridden branch
        XCTAssertEqual(result.url, "https://github.com/depop/my-app/tree/develop")
        // AND the ref is the overridden branch
        XCTAssertEqual(result.ref, "develop")
    }
}
