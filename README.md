# auto-session-title

Claude Code plugin that automatically generates session titles for sessions missing one.

## Problem

Claude Code uses `ai-title` to display session names in the `/resume` list. However, title generation is unreliable in certain scenarios:

| Scenario | Missing Title Rate |
|----------|-------------------|
| VS Code extension sessions | ~40% |
| CLI sessions starting with slash commands | Occasional |
| Long CLI sessions | Occasional |

Without a title, sessions show up as unrecognizable text snippets in `/resume`, making it difficult to find previous conversations.

Related GitHub Issues:
- [#29620](https://github.com/anthropics/claude-code/issues/29620) - Sessions disappear when first message is a slash command
- [#38973](https://github.com/anthropics/claude-code/issues/38973) - VS Code: older sessions not visible after update
- [#35647](https://github.com/anthropics/claude-code/issues/35647) - Add session title/summary to /resume list
- [#24119](https://github.com/anthropics/claude-code/issues/24119) - Auto-title sessions from CWD or project metadata

## How It Works

A `Stop` hook runs after every Claude response and checks if the current session has an `ai-title`. If not, it extracts the first meaningful user message and writes it as the title.

**Title format:** `{session-id-prefix}-{first-user-message}`

Example: `d9e9c4ac-整合平台欄位交叉比對分析與規劃`

The session ID prefix helps identify sessions even when the extracted text isn't descriptive enough.

**Performance:**
- Session already has title → `grep` exits immediately (< 5ms, no noticeable impact)
- Session has < 3 user messages → skipped (too short to need a title)
- Session needs title → extracts and writes once, then all future checks hit the fast path

**Smart extraction:**
- Skips IDE metadata tags (`<ide_opened_file>`, `<ide_selection>`, etc.)
- Skips command tags (`<command-message>`, `<local-command>`, etc.)
- Falls back to `Untitled (MM/DD)` if no meaningful text is found

## Requirements

- Python 3 (used for JSON parsing)
- Claude Code CLI

## Installation

```bash
claude plugins add hard25670559/auto-session-title
```

## Uninstallation

```bash
claude plugins remove auto-session-title
```

## License

MIT
