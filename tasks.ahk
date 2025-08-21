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

^Numpad3::
    Run, %refilePath%
return
