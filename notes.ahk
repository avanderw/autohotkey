#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
EnvGet, vUserProfile, USERPROFILE

IniRead, notesPath, settings.ini, Environment, notes-path
if (notesPath="ERROR") {
    InputBox, notesPath, Notes Inbox Path, Enter the path to your notes folder
    if ErrorLevel
        return
    IniWrite, %notesPath%, settings.ini, Environment, notes-path
}
StringReplace, notesPath, notesPath, ~, %vUserProfile%, All

^Numpad4::
Gui, Font, s12 c444444
Gui, Add, Edit, r9 w550 vNote WantTab, %Clipboard%
Gui, Add, Button, w550 h50, OK

Gui, Show,, Quick Note
return

ButtonOK:
Gui, Submit
FileAppend, %Note%, %notesPath%\%A_YYYY%%A_MM%%A_DD%T%A_Hour%%A_Min%%A_Sec%.md

GuiEscape:
GuiClose:
Gui, Destroy
return