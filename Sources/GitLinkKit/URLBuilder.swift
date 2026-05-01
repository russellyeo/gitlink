import Foundation

public enum URLBuilder {

    public static func buildURL(
        remote: GitRemote,
        ref: String,
        target: Target,
        isDirectory: Bool?
    ) throws -> String {
        switch remote.provider {
        case .gitHub:
            return buildGitHubURL(
                owner: remote.owner,
                repo: remote.repo,
                ref: ref,
                target: target,
                isDirectory: isDirectory
            )
        case .gitLab, .bitbucket:
            throw GitLinkError.providerNotSupported(
                provider: remote.provider.rawValue,
                issueURL: GitRemoteParser.issueURL
            )
        }
    }

    private static func buildGitHubURL(
        owner: String,
        repo: String,
        ref: String,
        target: Target,
        isDirectory: Bool?
    ) -> String {
        let base = "https://github.com/\(owner)/\(repo)"

        switch target {
        case .commit(let hash):
            return "\(base)/commit/\(hash)"

        case .repoRoot:
            return "\(base)/tree/\(ref)"

        case .path(let parsed):
            let pathType = (isDirectory ?? false) ? "tree" : "blob"
            let encodedPath = parsed.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? parsed.path
            var url = "\(base)/\(pathType)/\(ref)/\(encodedPath)"

            if let lineSpec = parsed.lineSpec {
                switch lineSpec {
                case .single(let line):
                    url += "#L\(line)"
                case .range(let start, let end):
                    url += "#L\(start)-L\(end)"
                }
            }

            return url
        }
    }
}
