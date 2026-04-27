import XCTest
@testable import GitLinkKit

final class MockGitService: GitService {
    var remoteURLResult: Result<String, Error> = .success("https://github.com/depop/my-app.git")
    var currentBranchResult: Result<String, Error> = .success("main")
    var repositoryRootResult: Result<String, Error> = .success("/tmp/repo")
    var resolveCommitResult: Result<String, Error> = .success("abc123def456")

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
        try resolveCommitResult.get()
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
        let url = try sut.generate(
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
        )

        // THEN the URL uses the current branch
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/feature/search/main.swift")
    }

    // MARK: - File URL with line range

    func test_generate_fileWithLineRange_includesLineFragment() throws {
        // GIVEN a file exists with 20 lines
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...20).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link with a line range
        let url = try sut.generate(
            input: "main.swift:12-20",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
        )

        // THEN the URL includes the line range fragment
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/main.swift#L12-L20")
    }

    // MARK: - Directory URL

    func test_generate_directory_usesTreePath() throws {
        // GIVEN a directory exists in the repo
        let dirPath = tempDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)

        // WHEN we generate a link for a directory
        let url = try sut.generate(
            input: "Sources",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
        )

        // THEN the URL uses tree/
        XCTAssertEqual(url, "https://github.com/depop/my-app/tree/main/Sources")
    }

    // MARK: - Branch override

    func test_generate_withBranchOverride_usesBranch() throws {
        // GIVEN a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we generate a link with a branch override
        let url = try sut.generate(
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: "develop",
            commit: nil
        )

        // THEN the URL uses the overridden branch
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/develop/main.swift")
    }

    // MARK: - Commit pinning

    func test_generate_withCommitHash_usesResolvedHash() throws {
        // GIVEN a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        // AND the resolved commit is a full hash
        mockGit.resolveCommitResult = .success("4f2d8d5a6f0d5f8d7c1234567890abcdef123456")

        // WHEN we generate a link with --commit HEAD
        let url = try sut.generate(
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: "HEAD"
        )

        // THEN the URL uses the commit hash
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/4f2d8d5a6f0d5f8d7c1234567890abcdef123456/main.swift")
    }

    func test_generate_withShortCommitHash_usesResolvedHash() throws {
        // GIVEN a file exists
        let filePath = tempDir.appendingPathComponent("main.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        // AND the resolved commit returns a full hash
        mockGit.resolveCommitResult = .success("abc123def456789")

        // WHEN we generate a link with a specific commit hash
        let url = try sut.generate(
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: "abc123"
        )

        // THEN the URL uses the resolved hash
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/abc123def456789/main.swift")
    }

    // MARK: - Error cases

    func test_generate_nonExistentFile_throwsPathNotFound() {
        // GIVEN a path that doesn't exist
        let expectedPath = tempDir.appendingPathComponent("nope.swift").path

        // WHEN we generate a link
        // THEN it throws pathNotFound
        XCTAssertThrowsError(try sut.generate(
            input: "nope.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
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
            input: "Sources:5",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
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
            input: "short.swift:10",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
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
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
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
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
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
        let url = try sut.generate(
            input: "Sources/App/main.swift:5",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
        )

        // THEN the path is relative to the repo root
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/Sources/App/main.swift#L5")
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
        let url = try sut.generate(
            input: "main.swift",
            workingDirectory: tempDir.path,
            branch: nil,
            commit: nil
        )

        // THEN the URL is correct
        XCTAssertEqual(url, "https://github.com/depop/my-app/blob/main/main.swift")
    }
}
