# AutoHotkey Productivity Scripts

A collection of AutoHotkey scripts for personal knowledge management and productivity. These scripts serve as a replacement for org-mode in Emacs, providing quick capture tools for tasks, notes, journal entries, and more.

## Requirements

- [AutoHotkey v1.1](https://www.autohotkey.com/) (not compatible with v2.0)
- Windows operating system

## Scripts

### Tasks (`tasks.ahk`)
Quick task management with priority support.

| Hotkey | Action |
| --- | --- |
| `CTRL+NUMPAD0` | Add task to inbox with optional priority (use `(A)` prefix) |
| `CTRL+NUMPAD3` | Open task refile directory |

Tasks are automatically timestamped with ISO date format (YYYY-MM-DD).

### Notes (`notes.ahk`)
Enhanced note-taking with YAML frontmatter, word count, and automatic metadata.

| Hotkey | Action |
| --- | --- |
| `CTRL+NUMPAD4` | Create enhanced note with timer and metadata |

Features:
- Write timer to track composition time
- Automatic YAML frontmatter generation
- Word count and estimated reading time
- Unique ID generation for each note
- Title extraction from first line
- Automatic filename generation with timestamp and title slug

### Journal (`journal.ahk`)
Automated daily journaling system with scheduled prompts.

**Automatic Features:**
- Daily journal prompt at 3:00 PM (15:00)
- Random thought capture prompts (between 9 AM - 4 PM)
- Persistent prompts across system sleep/wake
- Separate storage for journal entries and thought logs

**Prompt Options:**
- Save Entry - Write and save the journal entry
- Skip Today - Mark as complete without writing
- Remind Later - Re-prompt in 30 minutes
- Cancel - Close without action

### Clipboard Logger (`log-clipboard.ahk`)
Automatic clipboard history tracking.

| Hotkey | Action |
| --- | --- |
| `CTRL+SHIFT+C` | Open today's clipboard log |
| `CTRL+SHIFT+L` | Toggle clipboard logging on/off |

Features:
- Automatic logging of all text copied to clipboard
- Daily log files in markdown format
- Timestamped entries with code block formatting
- Non-intrusive tray notifications

### IDs (`ids.ahk`)
Quick date/time insertion for timestamping.

| Hotkey | Action |
| --- | --- |
| `CTRL+ALT+D` | Insert ISO date (YYYY-MM-DD) |
| `CTRL+ALT+T` | Insert ISO timestamp (YYYYMMDDTHHmmss) |

### Jokes (`jokes.ahk`)
Random joke display for a quick mental break.

| Hotkey | Action |
| --- | --- |
| `CTRL+NUMPAD9` | Display random joke from file |

The selected joke is automatically copied to clipboard.

## Configuration

All scripts use a shared `settings.ini` file for configuration. The file is created automatically on first run, or you can create it manually:

```ini
[Environment]
task-inbox=~\org\todo.txt
task-refile-path=~\org
notes-path=~\org\notes
journal-path=~\org\notes\journal
jokes-path=~\org\lists\jokes.txt

[Journal]
last-prompt-date=20251024
```

### Configuration Options

| Setting | Description | Default |
| --- | --- | --- |
| `task-inbox` | Path to task inbox file | `~\org\todo.txt` |
| `task-refile-path` | Directory for task organization | `~\org` |
| `notes-path` | Directory for notes | `~\org\notes` |
| `journal-path` | Directory for journal entries | `~\org\notes\journal` |
| `jokes-path` | Path to jokes text file | `~\org\lists\jokes.txt` |

**Note:** The `~` character is automatically expanded to your Windows user profile path.

## File Organization

```
~\org\
├── todo.txt                    # Task inbox
├── notes\                      # Enhanced notes
│   ├── clipboard-logs\         # Automatic clipboard history
│   ├── journal\                # Daily journal entries
│   └── thought-logs\           # Random thought captures
└── lists\
    └── jokes.txt               # One joke per line
```

## Running the Scripts

1. Install AutoHotkey v1.1
2. Clone or download this repository
3. Double-click any `.ahk` script to run it
4. Scripts will create `settings.ini` and prompt for paths on first run
5. Scripts run in the system tray - look for icons to confirm they're active

**Tip:** Add scripts to your Windows Startup folder to run automatically on login.

## License

Personal use scripts - modify and adapt as needed for your workflow.
