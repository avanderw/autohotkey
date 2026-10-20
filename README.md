# AutoHotkey Productivity Scripts

A collection of AutoHotkey scripts for personal knowledge management and productivity. These scripts serve as a replacement for org-mode in Emacs, providing quick capture tools for tasks, notes, and thoughts.

## Requirements

- [AutoHotkey v2.0](https://www.autohotkey.com/)
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
Enhanced note-taking with YAML frontmatter and optional note-type prefixes.

| Hotkey | Action |
| --- | --- |
| `CTRL+NUMPAD4` | Create enhanced note with timer and metadata |

Features:
- Write timer to track composition time
- Automatic YAML frontmatter generation
- Title extraction from first line
- Automatic filename generation with timestamp or `idea_` / `wip_` prefix and title slug
- Collision-safe naming when an `idea_` or `wip_` filename already exists

### Self-Check-In (`journal.ahk`)
Self-Check-In is a local Windows tray app, available from source or as a
self-contained executable. The pilot target is Windows 10/11 x64; clean-machine
acceptance testing is still required before a public release.

**Automatic Features:**
- Random thought prompts every 60-180 minutes during 9 AM-5 PM, including weekends by default
- A fixed 9 AM first prompt when the next interval falls outside active hours
- Persisted scheduling across restart; at most one catch-up prompt after sleep/unlock during active hours
- Separate Markdown files titled Self Check-in Log, with the timestamp in the heading only and values matching the displayed choices
- No account, network access, or telemetry; notes are unencrypted local files

**Prompt Options:**
- Save Thought saves a note and schedules the next prompt. Save failures keep the form and text open.
- Dismiss, Escape, and closing the thought window all schedule the next prompt without saving.

**Check-in Form:**
- One compact form sized to show all questions without scrolling on the tested display; no tab pages. Save Thought and Dismiss remain fixed at the bottom.
- Side-by-side battery/attention dropdowns and side-by-side activity/next-action dropdowns. Current context/mode was removed in v0.1.4, including from newly saved notes.
- Bold question headings with matching label-to-dropdown spacing; compact mood checkboxes and short body labels such as Tense / tight and At ease / relaxed.
- An inline optional headline; hover over its heading or input for the past-few-hours news-headline question. Short, lighter reflection prompts sit beside the answer box: gratitude, pride, and a kind message to yourself.
- Keyboard Tab follows the questions. Scrolling is retained only as a fallback when a small screen or high display scaling cannot accommodate the complete form. Tab from the answer box moves to Save rather than inserting a tab character.

Daily 3 PM journaling and its settings option were removed in v0.1.1. Existing
journal notes and obsolete configuration entries are left untouched but are no
longer read or written. Old energy/focus/improvement preference counts are not
reused for the new option lists. Obsolete context preference counts are left
untouched but are no longer used.

**Install and Run:**
1. Run the versioned Windows setup executable. Installation is per-user, without administrator access or an AutoHotkey installation.
2. Optionally select start-at-login, then launch Self-Check-In.
3. Choose a notes folder on first run. Canceling the picker accepts the Documents\Self-Check-In default.
4. Use the tray menu for Capture now, Pause reminders, Open notes folder, Settings, About, or Exit. Windows may place the icon under the tray overflow arrow.

When startup does not already show a capture, a tray notification confirms that
the app is running, states the next reminder (or paused status), and directs you
to Capture now and Settings. It does not reset the schedule or force an extra
prompt. Windows notification settings or Do Not Disturb may hide this cue; the
tray menu is still available.

The portable ZIP can instead be extracted and Self-Check-In.exe launched directly.
Portable and installed copies share per-user settings and cannot run together.
The ZIP is portable in deployment, not in data storage: settings still live in
%LOCALAPPDATA%\Self-Check-In\settings.ini. No loose icon is needed by the EXE.

Version 1.0.0 renames Thought Capture to Self-Check-In. On first run, the app
copies legacy %LOCALAPPDATA%\ThoughtCapture\settings.ini only if the new settings
file does not exist. The old copy remains untouched; notes paths, schedule state,
and preference counts are preserved. A configured notes folder is never moved.
Fresh installations default to Documents\Self-Check-In\logs.

The installer keeps the same application ID so it upgrades an existing install
rather than creating another one. An upgraded installation may retain its old
installation directory, but uses Self-Check-In.exe and the new shortcut. The old
default shortcut and executable are removed, and enabled start-at-login entries
are updated. The legacy mutex name and internal preference section are retained
for compatibility, preventing old and new copies from running together.

Tray Settings controls the notes folder, same-day active hours, interval range,
weekends, and start-at-login. Ctrl+Shift+D captures immediately,
even while automatic reminders are paused. Scheduled windows do not activate
themselves. Double-launching an active copy does nothing; use its tray icon.

New entries go to a single logs subfolder of the selected notes folder, defaulting
to Documents\Self-Check-In\logs for fresh installations. Open notes folder opens this logs directory.
Folder changes affect new notes only; existing notes are not moved. On upgrade,
old thought-logs and journal folders are left untouched; new entries go to logs
instead. Settings from the old shared repository settings.ini are not imported
or modified. The wider reflection textbox does not change how existing notes read.

The app cannot prompt while Windows is asleep, shut down, or locked. It checks
every 30 seconds while running; this is not an exact-time alarm. Times use the
current local wall clock. Changing the clock backwards can delay a persisted
prompt; saving Settings resets the schedule. Disabling Windows notifications
can hide save confirmations, but notes still save to disk. If the chosen folder
is inside OneDrive or another synced directory, that service may upload notes.

**Update and Uninstall:** Save or dismiss open captures, exit from the tray, and
run the new installer over the existing installation. The installer refuses to
continue while either Self-Check-In or its legacy version is running. Updates remain manual;
there is no automatic updater. Uninstall through Windows Settings > Apps.
Uninstall removes installed files and startup registration, but preserves notes
and per-user configuration. For the ZIP, disable start-at-login in Settings,
exit, then remove the extracted application files.

Pilot builds are unsigned and may trigger Windows reputation or antivirus
warnings. Do not disable security software. Verify the publisher/source and
SHA-256 checksum; use signed, reviewed releases for wider distribution.

### Build Self-Check-In

Build-machine requirements only: AutoHotkey v2 x64, the official
[Ahk2Exe compiler](https://github.com/AutoHotkey/Ahk2Exe/releases), and optionally
[Inno Setup 6.3+](https://jrsoftware.org/isdl.php). Recipients need none of these.
The first local build used AutoHotkey 2.0.19, Ahk2Exe 1.1.37.02a2, and Inno Setup
6.7.3. The compiler's 1.1 version number does not change the selected v2 runtime.

Extract Ahk2Exe to .tools so .tools\Ahk2Exe.exe exists. Inno Setup's own installer
supports /PORTABLE=1 /CURRENTUSER with /DIR pointing to .tools\Inno Setup 6;
alternatively install it normally for the current user and supply -IsccPath.
Download tools only from official releases and verify signatures where provided.

```powershell
.\build.ps1 -TestsOnly
.\build.ps1 -SkipInstaller
.\build.ps1
```

Override -AhkPath, -CompilerPath, -IsccPath, and -RuntimeLicense when tools live
elsewhere. The selected base must be the standard, non-UIAccess x64 v2 runtime.
Tests use temporary settings and notes, and briefly open test capture windows;
they do not modify your real app configuration or shared settings.ini.

The build embeds the icon and version, checks the resulting executable, exercises
standalone capture, then creates dist\Self-Check-In.exe, a versioned portable
ZIP, an optional versioned installer, build-info.json, and SHA256SUMS.txt.
Artifacts contain only explicit inputs, never repository settings or notes.
The manifest records runtime/compiler versions and hashes. Build outputs and
downloaded tools are ignored by Git. Ignoring settings.ini does not untrack an
already tracked copy; do not commit personal changes to it.

Before distributing, finish the gates in [todo.md](todo.md), especially clean-VM
testing, signing decisions, icon permission, and runtime/application licensing
review in [THIRD-PARTY.md](THIRD-PARTY.md). The current artifacts are local pilot
builds, not a published or fully accepted release.

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

The other scripts use a shared `settings.ini` file for configuration. Thought
Capture now uses its own per-user settings and Settings window, described above.
For the other scripts, the shared file is created automatically or can be created manually:

```ini
[Environment]
task-inbox=~\org\todo.txt
task-refile-path=~\org
notes-path=~\org\notes
jokes-path=~\org\lists\jokes.txt
```

### Configuration Options

| Setting | Description | Default |
| --- | --- | --- |
| `task-inbox` | Path to task inbox file | `~\org\todo.txt` |
| `task-refile-path` | Directory for task organization | `~\org` |
| `notes-path` | Directory for notes | `~\org\notes` |
| `jokes-path` | Path to jokes text file | `~\org\lists\jokes.txt` |

**Note:** The `~` character is automatically expanded to your Windows user profile path.

## File Organization

```
~\org\
├── todo.txt                    # Task inbox
├── notes\                      # Enhanced notes
│   ├── clipboard-logs\         # Automatic clipboard history
│   └── logs\                   # Self check-in logs if this notes folder is selected
└── lists\
    └── jokes.txt               # One joke per line
```

## Running the Scripts

1. Install AutoHotkey v2.0
2. Clone or download this repository
3. Double-click any `.ahk` script to run it
4. Scripts create their settings on first run; Self-Check-In uses its own per-user settings and folder picker
5. Scripts run in the system tray - look for icons to confirm they're active

**Tip:** Add scripts to your Windows Startup folder to run automatically on login.

## License

The original application code and documentation are licensed under the
[MIT License](LICENSE), Copyright (c) 2026 Andrew van der Westhuizen.
You may use, modify, redistribute, and sell copies, provided the copyright and
permission notice are retained. An in-app author credit is not required by MIT.

The reminder-bell icon is [Lucide bell-ring](https://lucide.dev/icons/bell-ring),
from Lucide 0.468.0 under the ISC license. Its original source is check-in.svg;
check-in.ico is a teal Windows conversion with sizes 16-256 pixels. Attribution
and terms are bundled in [ICON-LICENSE.txt](ICON-LICENSE.txt). A local sharp 0.34.3
rasterizer was used for conversion; it is a build tool and is not redistributed.

The embedded AutoHotkey runtime retains its separate upstream license. See
[THIRD-PARTY.md](THIRD-PARTY.md) for notices and remaining runtime redistribution
requirements. Application licensing does not replace third-party terms.
