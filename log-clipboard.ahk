#Requires AutoHotkey v2.0

; Clipboard Logger
; Automatically log clipboard content changes to daily text files

SetupConfig()
SetTrayTip()
TrayTip("Clipboard Logger", "Clipboard logging started`n`nCtrl+Shift+C - Open today's log`nCtrl+Shift+L - Toggle logging", 1)
SetTimer(() => TrayTip(), 2000)
OnClipboardChange(LogClipboard)

/**
 * Log clipboard content to daily markdown file
 * Type: 1 = text, 2 = files/images, 0 = empty
 */
LogClipboard(Type) {
    global clipboardLogsPath
    
    if (Type != 1)  ; Only process text content
        return
    
    clipContent := A_Clipboard
    if (clipContent = "")  ; Ignore empty content
        return
    
    try {
        currentDate := FormatTime(A_Now, "yyyy-MM-dd")
        logFile := clipboardLogsPath . "\" . currentDate . ".md"
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        
        ; Format log entry as Markdown
        logEntry := "`n## " . timestamp . "`n`n"
        logEntry .= clipContent . "`n`n"
        logEntry .= "---`n"
        
        FileAppend(logEntry, logFile, "UTF-8")
        
        ; Show success notification
        clipPreview := SubStr(clipContent, 1, 50) . (StrLen(clipContent) > 50 ? "..." : "")
        TrayTip("Clipboard Logger", "Logged: " clipPreview, 1)
        SetTimer(() => TrayTip(), 2000)
    } catch as err {
        TrayTip("Clipboard Logger", "Error: " err.What, 3)
        SetTimer(() => TrayTip(), 3000)
    }
}

RemoveToolTip() {
    TrayTip()
}

; Hotkey to open today's clipboard log
^+c:: {
    global clipboardLogsPath
    
    currentDate := FormatTime(A_Now, "yyyy-MM-dd")
    logFile := clipboardLogsPath . "\" . currentDate . ".md"
    
    if (FileExist(logFile)) {
        Run(logFile)
    } else {
        MsgBox("No clipboard log exists for today yet.", "No Log Found", 48)
    }
}

; Hotkey to toggle clipboard logging on/off
^+l:: {
    if (A_IsPaused) {
        A_TrayMenu.Tip := "Clipboard Logger"
        TrayTip("Clipboard Logger", "Logging enabled", 1)
        Pause(False)
    } else {
        A_TrayMenu.Tip := "Clipboard Logger (Paused)"
        TrayTip("Clipboard Logger", "Logging paused", 2)
        Pause(True)
    }
    SetTimer(() => TrayTip(), 2000)
}

SetupConfig() {
    global clipboardLogsPath
    
    userProfile := EnvGet("USERPROFILE")
    clipboardLogsPathConfig := IniRead(A_ScriptDir . "\settings.ini", "Environment", "clipboard-logs-path", "")
    
    if (clipboardLogsPathConfig = "") {
        clipboardLogsPathConfig := "~\org\notes\80 System\clipboard-logs"
        IniWrite(clipboardLogsPathConfig, A_ScriptDir . "\settings.ini", "Environment", "clipboard-logs-path")
    }
    
    clipboardLogsPath := StrReplace(clipboardLogsPathConfig, "~", userProfile)
    
    try {
        DirCreate(clipboardLogsPath)
    }
}

SetTrayTip() {
    try {
        A_TrayMenu.SetIcon(A_ScriptDir . "\clipboard.ico", 1)
    }
    A_TrayMenu.Tip := "Clipboard Logger"
}
