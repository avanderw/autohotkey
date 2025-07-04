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
Duration := Round((A_TickCount - Start)/1000, 0)
Minutes := Floor(Duration / 60)
Seconds := Mod(Duration, 60)
DurationText := (Minutes > 0 ? Minutes . "m " : "") . Seconds . "s"

; Extract title from first line if it's a markdown H1 (before adding front-matter)
fileName := A_YYYY . A_MM . A_DD . "T" . A_Hour . A_Min . A_Sec
firstLine := ""
noteTitle := ""
Loop, Parse, Note, `n, `r
{
    firstLine := A_LoopField
    break
}

if (SubStr(firstLine, 1, 2) = "# ") {
    noteTitle := SubStr(firstLine, 3)
    ; Create clean filename from title
    title := noteTitle
    StringLower, title, title
    StringReplace, title, title, %A_Space%, -, All
    ; Remove any characters that aren't alphanumeric, hyphens, or underscores
    title := RegExReplace(title, "[^a-z0-9\-_]", "")
    if (title != "") {
        fileName := fileName . "_" . title
    }
}

; Create YAML front-matter with title
createdDate := A_YYYY . "-" . A_MM . "-" . A_DD
createdTime := A_Hour . ":" . A_Min . ":" . A_Sec
createdDateTime := createdDate . "T" . createdTime
frontMatter := "---`n"
if (noteTitle != "") {
    frontMatter .= "title: " . noteTitle . "`n"
}
frontMatter .= "created: " . createdDateTime . "`n"
frontMatter .= "duration: " . DurationText . "`n"
frontMatter .= "---`n`n"

Note := frontMatter . Note

FileAppend, %Note%, %notesPath%\%fileName%.md

GuiEscape:
GuiClose:
Gui, Destroy
GuiCount := GuiCount -1
return