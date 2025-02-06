#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
EnvGet, vUserProfile, USERPROFILE
Menu, Tray, Icon, check-square.ico
Menu, Tray, Tip, Quick Tasks

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

^Numpad0:: ; add task to inbox
InputBox, task, Add Task, Enter the task you want to complete
if ErrorLevel
    return
if (Trim(task)="")
    return
FormatTime, AddedDate,, yyyy-MM-dd
FileAppend, %AddedDate% %task%`r`n, %inbox%
return

^Numpad3:: ; open tasks folder
Run, %refilePath%
return
