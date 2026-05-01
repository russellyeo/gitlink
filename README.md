# gitlink

Generate shareable GitHub URLs from your local git working copy — files, lines, commits, and more.

## Usage

```
gitlink [options] [<path>[:<line>[-<end_line>]]]
```

### Options

| Option | Description |
|---|---|
| `--commit <hash>` | Pin to a commit hash (e.g. `--commit HEAD` or `--commit abc123`). |
| `--branch <name>` | Use a specific branch instead of the current one. |
| `--output <format>` | Output format: `url` (default) or `markdown`. |
| `--copy` | Copy the output to the system clipboard. |
| `--help` | Show help information. |

### Examples

```bash
# Repo root on current branch
gitlink
# → https://github.com/your-org/your-repo/tree/feature-x

# Repo root on a specific branch
gitlink --branch develop
# → https://github.com/your-org/your-repo/tree/develop

# Commit page
gitlink --commit abc123
# → https://github.com/your-org/your-repo/commit/abc123...

# File on current branch
gitlink Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift

# File with line range
gitlink Sources/App/main.swift:12-20
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12-L20

# Single line
gitlink Sources/App/main.swift:12
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12

# Directory
gitlink Sources/App/
# → https://github.com/your-org/your-repo/tree/feature-x/Sources/App

# File pinned to a commit
gitlink --commit HEAD Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/4f2d8d5.../Sources/App/main.swift

# Use a specific branch
gitlink --branch main Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/main/Sources/App/main.swift

# Copy to clipboard
gitlink --copy Sources/App/main.swift

# Markdown link
gitlink --output markdown Sources/App/main.swift:12-20
# → [Sources/App/main.swift#L12-L20](https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12-L20)
```

## Installation

### Mint

```bash
mint install russellyeo/gitlink
```

### Build from source

Requirements:

- macOS 13+
- Swift 5.9+

```bash
git clone https://github.com/russellyeo/gitlink.git
cd gitlink
swift build -c release
sudo cp .build/release/gitlink /usr/local/bin/
```
