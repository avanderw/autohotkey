#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
EnvGet, vUserProfile, USERPROFILE
Menu, Tray, Icon, clipboard.ico
Menu, Tray, Tip, Clipboard Logger

; Get notes path from settings (clipboard logs will go in clipboard-logs subdirectory)
IniRead, notesPath, settings.ini, Environment, notes-path
if (notesPath="ERROR") {
    notesPath = ~\org\notes
    IniWrite, %notesPath%, settings.ini, Environment, notes-path
}
StringReplace, notesPath, notesPath, ~, %vUserProfile%, All

; Set up clipboard logs path (similar to journal's thought-logs)
clipboardLogsPath := notesPath . "\clipboard-logs"

; Create clipboard logs directory if it doesn't exist
FileCreateDir, %clipboardLogsPath%

; Monitor clipboard changes
OnClipboardChange("LogClipboard")

return

LogClipboard(Type) {
    global clipboardLogsPath
    
    ; Type 0 = clipboard is now empty
    ; Type 1 = clipboard contains text or HTML
    ; Type 2 = clipboard contains non-text (image, files, etc.)
    
    ; Only process text content
    if (Type != 1)
        return
    
    ; Get clipboard content
    clipContent := Clipboard
    
    ; Ignore empty content
    if (clipContent = "")
        return
    
    ; Get current date for filename
    FormatTime, currentDate, , yyyy-MM-dd
    logFile := clipboardLogsPath . "\" . currentDate . ".md"
    
    ; Get current timestamp
    FormatTime, timestamp, , yyyy-MM-dd HH:mm:ss
    
    ; Prepare log entry with markdown formatting
    logEntry := "`n" . "## " . timestamp . "`n`n"
    logEntry .= "``````text`n"
    logEntry .= clipContent . "`n"
    logEntry .= "``````"  . "`n"
    
    ; Append to file
    FileAppend, %logEntry%, %logFile%, UTF-8
    
    if ErrorLevel {
        TrayTip, Clipboard Logger Error, Failed to write to log file, 3, 3
    } else {
        ; Show success notification
        clipPreview := SubStr(clipContent, 1, 50)
        if (StrLen(clipContent) > 50)
            clipPreview .= "..."
        TrayTip, Clipboard Logged, %clipPreview%, 2, 1
        SetTimer, RemoveTrayTip, 2000
    }
    
    return
}

RemoveTrayTip:
SetTimer, RemoveTrayTip, Off
TrayTip
return

; Hotkey to open today's clipboard log
^+c::
FormatTime, currentDate, , yyyy-MM-dd
logFile := clipboardLogsPath . "\" . currentDate . ".md"
IfExist, %logFile%
{
    Run, %logFile%
}
else
{
    MsgBox, 48, No Log Found, No clipboard log exists for today yet.
}
return

; Hotkey to toggle clipboard logging on/off
^+l::
if (A_IsPaused) {
    Menu, Tray, Tip, Clipboard Logger
    TrayTip, Clipboard Logger, Logging enabled, 2, 1
    Pause, Off
} else {
    Menu, Tray, Tip, Clipboard Logger (Paused)
    TrayTip, Clipboard Logger, Logging paused, 2, 2
    Pause, On
}
SetTimer, RemoveTrayTip, 2000
return
