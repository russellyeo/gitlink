import Foundation

public enum URLBuilder {

    public static func buildURL(
        remote: GitRemote,
        ref: String,
        path: String,
        isDirectory: Bool,
        lineSpec: LineSpec?
    ) throws -> String {
        switch remote.provider {
        case .gitHub:
            return buildGitHubURL(
                owner: remote.owner,
                repo: remote.repo,
                ref: ref,
                path: path,
                isDirectory: isDirectory,
                lineSpec: lineSpec
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
        path: String,
        isDirectory: Bool,
        lineSpec: LineSpec?
    ) -> String {
        let pathType = isDirectory ? "tree" : "blob"
        var url = "https://github.com/\(owner)/\(repo)/\(pathType)/\(ref)/\(path)"

        if let lineSpec {
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
