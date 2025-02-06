#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
EnvGet, vUserProfile, USERPROFILE
Menu, Tray, Icon, file-text.ico
Menu, Tray, Tip, Quick Notes

IniRead, notesPath, settings.ini, Environment, notes-path
if (notesPath="ERROR") {
    InputBox, notesPath, Notes Inbox Path, Enter the path to your notes folder
    if ErrorLevel
        return
    IniWrite, %notesPath%, settings.ini, Environment, notes-path
}
StringReplace, notesPath, notesPath, ~, %vUserProfile%, All

GuiCount := 1
^Numpad4::
Start := A_TickCount

Gui, %GuiCount%:Font, s12 c444444
Gui, %GuiCount%:Add, Edit, r24 w800 vNote WantTab, %Clipboard%
Gui, %GuiCount%:Add, Button, w800 h50, OK

Gui, %GuiCount%:Show,, Quick Note
GuiCount := GuiCount + 1
return

ButtonOK:
Gui, Submit
Duration := Round((A_TickCount - Start)/1000, 1)
Note := Note . "`n*--Took " . Duration . "s to write--*`n"
FileAppend, %Note%, %notesPath%\%A_YYYY%%A_MM%%A_DD%T%A_Hour%%A_Min%%A_Sec%.md

GuiEscape:
GuiClose:
Gui, Destroy
GuiCount := GuiCount -1
return