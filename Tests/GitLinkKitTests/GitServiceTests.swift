import XCTest
@testable import GitLinkKit

final class GitServiceTests: XCTestCase {

    // MARK: - GitHub HTTPS remote parsing

    func test_parseRemoteURL_gitHubHTTPSWithGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an HTTPS GitHub remote URL with .git suffix
        let remoteURL = "https://github.com/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        XCTAssertEqual(result.provider, .gitHub)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    func test_parseRemoteURL_gitHubHTTPSWithoutGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an HTTPS GitHub remote URL without .git suffix
        let remoteURL = "https://github.com/depop/my-app"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        XCTAssertEqual(result.provider, .gitHub)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    // MARK: - GitHub SSH remote parsing

    func test_parseRemoteURL_gitHubSSHWithGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an SSH GitHub remote URL with .git suffix
        let remoteURL = "git@github.com:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        XCTAssertEqual(result.provider, .gitHub)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    func test_parseRemoteURL_gitHubSSHWithoutGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an SSH GitHub remote URL without .git suffix
        let remoteURL = "git@github.com:depop/my-app"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        XCTAssertEqual(result.provider, .gitHub)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    // MARK: - GitLab remote parsing

    func test_parseRemoteURL_gitLabHTTPS_detectsGitLab() {
        // GIVEN an HTTPS GitLab remote URL
        let remoteURL = "https://gitlab.com/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitLab and owner/repo are extracted
        XCTAssertEqual(result.provider, .gitLab)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    func test_parseRemoteURL_gitLabSSH_detectsGitLab() {
        // GIVEN an SSH GitLab remote URL
        let remoteURL = "git@gitlab.com:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitLab and owner/repo are extracted
        XCTAssertEqual(result.provider, .gitLab)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    // MARK: - Bitbucket remote parsing

    func test_parseRemoteURL_bitbucketHTTPS_detectsBitbucket() {
        // GIVEN an HTTPS Bitbucket remote URL
        let remoteURL = "https://bitbucket.org/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is Bitbucket and owner/repo are extracted
        XCTAssertEqual(result.provider, .bitbucket)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    func test_parseRemoteURL_bitbucketSSH_detectsBitbucket() {
        // GIVEN an SSH Bitbucket remote URL
        let remoteURL = "git@bitbucket.org:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the provider is Bitbucket and owner/repo are extracted
        XCTAssertEqual(result.provider, .bitbucket)
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    // MARK: - Unknown remotes

    func test_parseRemoteURL_unknownHost_throwsUnknownRemote() {
        // GIVEN a remote URL with an unrecognised host
        let remoteURL = "https://codeberg.org/depop/my-app.git"

        // WHEN we parse the remote URL
        // THEN it throws an unknownRemote error
        XCTAssertThrowsError(try GitRemoteParser.parse(remoteURL)) { error in
            XCTAssertEqual(error as? GitLinkError, .unknownRemote(remoteURL))
        }
    }

    func test_parseRemoteURL_malformedURL_throwsUnknownRemote() {
        // GIVEN a malformed remote URL
        let remoteURL = "not-a-url"

        // WHEN we parse the remote URL
        // THEN it throws an unknownRemote error
        XCTAssertThrowsError(try GitRemoteParser.parse(remoteURL)) { error in
            XCTAssertEqual(error as? GitLinkError, .unknownRemote(remoteURL))
        }
    }
}
