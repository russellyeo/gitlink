import ArgumentParser

@main
struct GHLink: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate GitHub links from local file paths."
    )

    func run() throws {}
}
