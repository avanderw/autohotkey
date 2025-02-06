#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
EnvGet, vUserProfile, USERPROFILE

Menu, Tray, Icon, check-square.ico
Menu, Tray, Tip, Quick Tasks

; Read settings
IniRead, inbox, settings.ini, Environment, task-inbox
if (inbox="ERROR") {
    InputBox, inbox, Task Inbox Path, Enter the path to your task inbox
    if ErrorLevel
        return
    IniWrite, %inbox%, settings.ini, Environment, task-inbox
}
StringReplace, inbox, inbox, ~, %vUserProfile%, All

IniRead, refilePath, settings.ini, Environment, task-refile-path
if (refilePath="ERROR") {
    InputBox, refilePath, Task Refile Path, Enter the path to your task refile folder
    if ErrorLevel
        return
    IniWrite, %refilePath%, settings.ini, Environment, task-refile-path
}
StringReplace, refilePath, refilePath, ~, %vUserProfile%, All

^Numpad0:: ; add task via simple input box with priority parsing
    InputBox, task, Add Task, Enter task (start with (A) for priority)
    if ErrorLevel
        return
    if (Trim(task)="")
        return
        
    FormatTime, AddedDate,, yyyy-MM-dd
    
    ; Check for priority pattern (X) at start
    if RegExMatch(task, "^\(([A-Z])\)\s*(.*)$", match) {
        task := "(" match1 ") " AddedDate " " match2
    } else {
        task := AddedDate " " task
    }
    
    FileAppend, %task%`r`n, %inbox%
return

^Numpad1:: ; Toggle completion of current line
    ; Store clipboard content
    ClipSaved := ClipboardAll
    
    ; Get current line
    Send, {Home}+{End}^c
    Sleep, 50
    line := Clipboard
    
    ; Toggle completion
	FormatTime, CompletionDate,, yyyy-MM-dd
    if (SubStr(line, 1, 2) = "x ") {
        ; Remove completion and date
        RegExMatch(line, "^x \d{4}-\d{2}-\d{2} (.*)$", match)
        line := match1
    } else {
        ; Add completion, remove priority if exists
        RegExMatch(line, "^(?:\([A-Z]\) )?(.*)$", match)
        line := "x " CompletionDate " " match1
    }
    
    ; Replace line
    Clipboard := line
    Send, {Home}+{End}^v
    
    ; Restore clipboard
    Clipboard := ClipSaved
return

^Numpad3::
    Run, %refilePath%
return
