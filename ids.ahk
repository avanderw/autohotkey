#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

^!d:: ; Send the isodate to the cursor position
FormatTime, CurrentDateTime,, yyyy-MM-dd
SendInput %CurrentDateTime%
return

^!t:: ; Send the isotime to the cursor position
FormatTime, CurrentDateTime,, yyyyMMddTHHmmss
SendInput %CurrentDateTime%
return
