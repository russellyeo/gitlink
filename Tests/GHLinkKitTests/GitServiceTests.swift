import XCTest
@testable import GHLinkKit

final class GitServiceTests: XCTestCase {

    // MARK: - HTTPS remote parsing

    func test_parseRemoteURL_httpsWithGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an HTTPS remote URL with .git suffix
        let remoteURL = "https://github.com/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the owner and repo are extracted
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    func test_parseRemoteURL_httpsWithoutGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an HTTPS remote URL without .git suffix
        let remoteURL = "https://github.com/depop/my-app"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the owner and repo are extracted
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    // MARK: - SSH remote parsing

    func test_parseRemoteURL_sshWithGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an SSH remote URL with .git suffix
        let remoteURL = "git@github.com:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the owner and repo are extracted
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    func test_parseRemoteURL_sshWithoutGitSuffix_extractsOwnerAndRepo() {
        // GIVEN an SSH remote URL without .git suffix
        let remoteURL = "git@github.com:depop/my-app"

        // WHEN we parse the remote URL
        let result = try! GitRemoteParser.parse(remoteURL)

        // THEN the owner and repo are extracted
        XCTAssertEqual(result.owner, "depop")
        XCTAssertEqual(result.repo, "my-app")
    }

    // MARK: - Non-GitHub remotes

    func test_parseRemoteURL_gitLabURL_throwsNotGitHubRemote() {
        // GIVEN a GitLab remote URL
        let remoteURL = "https://gitlab.com/depop/my-app.git"

        // WHEN we parse the remote URL
        // THEN it throws a notGitHubRemote error
        XCTAssertThrowsError(try GitRemoteParser.parse(remoteURL)) { error in
            XCTAssertEqual(error as? GHLinkError, .notGitHubRemote(remoteURL))
        }
    }

    func test_parseRemoteURL_bitbucketSSH_throwsNotGitHubRemote() {
        // GIVEN a Bitbucket SSH remote URL
        let remoteURL = "git@bitbucket.org:depop/my-app.git"

        // WHEN we parse the remote URL
        // THEN it throws a notGitHubRemote error
        XCTAssertThrowsError(try GitRemoteParser.parse(remoteURL)) { error in
            XCTAssertEqual(error as? GHLinkError, .notGitHubRemote(remoteURL))
        }
    }

    // MARK: - Malformed URLs

    func test_parseRemoteURL_malformedURL_throwsNotGitHubRemote() {
        // GIVEN a malformed remote URL
        let remoteURL = "not-a-url"

        // WHEN we parse the remote URL
        // THEN it throws a notGitHubRemote error
        XCTAssertThrowsError(try GitRemoteParser.parse(remoteURL)) { error in
            XCTAssertEqual(error as? GHLinkError, .notGitHubRemote(remoteURL))
        }
    }
}
