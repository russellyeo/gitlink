// URLBuilder.swift
// GHLinkKit
// 2026-04-27 — Russell Yeo

import Foundation

public enum URLBuilder {

    public static func buildURL(
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
