import Foundation

public struct GitRemote: Equatable {
    public let owner: String
    public let repo: String
}

public enum GitRemoteParser {

    public static func parse(_ remoteURL: String) throws -> GitRemote {
        // SSH format: git@github.com:owner/repo.git
        if remoteURL.hasPrefix("git@github.com:") {
            let path = String(remoteURL.dropFirst("git@github.com:".count))
            return try extractOwnerRepo(from: path, remoteURL: remoteURL)
        }

        // HTTPS format: https://github.com/owner/repo.git
        if let url = URL(string: remoteURL),
           url.host() == "github.com" {
            let path = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
            return try extractOwnerRepo(from: path, remoteURL: remoteURL)
        }

        throw GHLinkError.notGitHubRemote(remoteURL)
    }

    private static func extractOwnerRepo(from path: String, remoteURL: String) throws -> GitRemote {
        var cleaned = path
        if cleaned.hasSuffix(".git") {
            cleaned = String(cleaned.dropLast(4))
        }

        let parts = cleaned.split(separator: "/")
        guard parts.count == 2 else {
            throw GHLinkError.notGitHubRemote(remoteURL)
        }

        return GitRemote(owner: String(parts[0]), repo: String(parts[1]))
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
        try run("git", "remote", "get-url", "origin")
    }

    public func currentBranch() throws -> String {
        let branch = try run("git", "rev-parse", "--abbrev-ref", "HEAD")
        if branch == "HEAD" {
            throw GHLinkError.notOnAnyBranch
        }
        return branch
    }

    public func repositoryRoot() throws -> String {
        try run("git", "rev-parse", "--show-toplevel")
    }

    public func resolveCommit(_ ref: String?) throws -> String {
        let argument = ref ?? "HEAD"
        do {
            return try run("git", "rev-parse", argument)
        } catch {
            throw GHLinkError.commitNotFound(argument)
        }
    }

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
            throw GHLinkError.notAGitRepository
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
