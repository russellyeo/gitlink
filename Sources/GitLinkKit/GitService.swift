import Foundation

public enum Provider: String, Equatable {
    case gitHub = "GitHub"
    case gitLab = "GitLab"
    case bitbucket = "Bitbucket"
}

public struct GitRemote: Equatable {
    public let provider: Provider
    public let owner: String
    public let repo: String
}

public enum GitRemoteParser {

    static let issueURL = "https://github.com/russellyeo/gitlink/issues"

    private static let providerMap: [(host: String, sshPrefix: String, provider: Provider)] = [
        ("github.com", "git@github.com:", .gitHub),
        ("gitlab.com", "git@gitlab.com:", .gitLab),
        ("bitbucket.org", "git@bitbucket.org:", .bitbucket),
    ]

    public static func parse(_ remoteURL: String) throws -> GitRemote {
        for entry in providerMap {
            if remoteURL.hasPrefix(entry.sshPrefix) {
                let path = String(remoteURL.dropFirst(entry.sshPrefix.count))
                return try extractOwnerRepo(from: path, provider: entry.provider, remoteURL: remoteURL)
            }
        }

        if let url = URL(string: remoteURL), let host = url.host() {
            for entry in providerMap {
                if host == entry.host {
                    let path = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
                    return try extractOwnerRepo(from: path, provider: entry.provider, remoteURL: remoteURL)
                }
            }
        }

        throw GitLinkError.unknownRemote(remoteURL)
    }

    private static func extractOwnerRepo(from path: String, provider: Provider, remoteURL: String) throws -> GitRemote {
        var cleaned = path
        if cleaned.hasSuffix(".git") {
            cleaned = String(cleaned.dropLast(4))
        }

        let parts = cleaned.split(separator: "/")
        guard parts.count == 2 else {
            throw GitLinkError.unknownRemote(remoteURL)
        }

        return GitRemote(provider: provider, owner: String(parts[0]), repo: String(parts[1]))
    }
}

public protocol GitService {
    func remoteURL() throws -> String
    func currentBranch() throws -> String
    func repositoryRoot() throws -> String
    func resolveCommit(_ ref: String?) throws -> String
}

public final class ShellGitService: GitService {

    public init() {}

    public func remoteURL() throws -> String {
        do {
            return try run("git", "remote", "get-url", "origin")
        } catch {
            throw GitLinkError.noOriginRemote
        }
    }

    public func currentBranch() throws -> String {
        let branch: String
        do {
            branch = try run("git", "rev-parse", "--abbrev-ref", "HEAD")
        } catch {
            throw GitLinkError.notAGitRepository
        }
        if branch == "HEAD" {
            throw GitLinkError.notOnAnyBranch
        }
        return branch
    }

    public func repositoryRoot() throws -> String {
        do {
            return try run("git", "rev-parse", "--show-toplevel")
        } catch {
            throw GitLinkError.notAGitRepository
        }
    }

    public func resolveCommit(_ ref: String?) throws -> String {
        let argument = ref ?? "HEAD"
        do {
            return try run("git", "rev-parse", argument)
        } catch {
            throw GitLinkError.commitNotFound(argument)
        }
    }

    private struct ShellError: Error {}

    private func run(_ args: String...) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ShellError()
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
