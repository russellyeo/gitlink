import Testing
@testable import GitLinkKit

@Suite struct GitServiceTests {

    // MARK: - GitHub HTTPS remote parsing

    @Test func parseRemoteURL_gitHubHTTPSWithGitSuffix_extractsOwnerAndRepo() throws {
        // GIVEN an HTTPS GitHub remote URL with .git suffix
        let remoteURL = "https://github.com/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        #expect(result.provider == .gitHub)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    @Test func parseRemoteURL_gitHubHTTPSWithoutGitSuffix_extractsOwnerAndRepo() throws {
        // GIVEN an HTTPS GitHub remote URL without .git suffix
        let remoteURL = "https://github.com/depop/my-app"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        #expect(result.provider == .gitHub)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    // MARK: - GitHub SSH remote parsing

    @Test func parseRemoteURL_gitHubSSHWithGitSuffix_extractsOwnerAndRepo() throws {
        // GIVEN an SSH GitHub remote URL with .git suffix
        let remoteURL = "git@github.com:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        #expect(result.provider == .gitHub)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    @Test func parseRemoteURL_gitHubSSHWithoutGitSuffix_extractsOwnerAndRepo() throws {
        // GIVEN an SSH GitHub remote URL without .git suffix
        let remoteURL = "git@github.com:depop/my-app"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitHub and owner/repo are extracted
        #expect(result.provider == .gitHub)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    // MARK: - GitLab remote parsing

    @Test func parseRemoteURL_gitLabHTTPS_detectsGitLab() throws {
        // GIVEN an HTTPS GitLab remote URL
        let remoteURL = "https://gitlab.com/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitLab and owner/repo are extracted
        #expect(result.provider == .gitLab)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    @Test func parseRemoteURL_gitLabSSH_detectsGitLab() throws {
        // GIVEN an SSH GitLab remote URL
        let remoteURL = "git@gitlab.com:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is GitLab and owner/repo are extracted
        #expect(result.provider == .gitLab)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    // MARK: - Bitbucket remote parsing

    @Test func parseRemoteURL_bitbucketHTTPS_detectsBitbucket() throws {
        // GIVEN an HTTPS Bitbucket remote URL
        let remoteURL = "https://bitbucket.org/depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is Bitbucket and owner/repo are extracted
        #expect(result.provider == .bitbucket)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    @Test func parseRemoteURL_bitbucketSSH_detectsBitbucket() throws {
        // GIVEN an SSH Bitbucket remote URL
        let remoteURL = "git@bitbucket.org:depop/my-app.git"

        // WHEN we parse the remote URL
        let result = try GitRemoteParser.parse(remoteURL)

        // THEN the provider is Bitbucket and owner/repo are extracted
        #expect(result.provider == .bitbucket)
        #expect(result.owner == "depop")
        #expect(result.repo == "my-app")
    }

    // MARK: - Unknown remotes

    @Test func parseRemoteURL_unknownHost_throwsUnknownRemote() {
        // GIVEN a remote URL with an unrecognised host
        let remoteURL = "https://codeberg.org/depop/my-app.git"

        // WHEN we parse the remote URL
        // THEN it throws an unknownRemote error
        #expect(throws: GitLinkError.unknownRemote(remoteURL)) {
            try GitRemoteParser.parse(remoteURL)
        }
    }

    @Test func parseRemoteURL_malformedURL_throwsUnknownRemote() {
        // GIVEN a malformed remote URL
        let remoteURL = "not-a-url"

        // WHEN we parse the remote URL
        // THEN it throws an unknownRemote error
        #expect(throws: GitLinkError.unknownRemote(remoteURL)) {
            try GitRemoteParser.parse(remoteURL)
        }
    }
}
