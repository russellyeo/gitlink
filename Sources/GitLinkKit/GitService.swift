import Foundation

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

        process.executableURL = URL(filePath: "/usr/bin/env")
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
