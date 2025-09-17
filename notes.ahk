#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
EnvGet, vUserProfile, USERPROFILE
Menu, Tray, Icon, file-text.ico
Menu, Tray, Tip, Enhanced Notes

IniRead, notesPath, settings.ini, Environment, notes-path
if (notesPath="ERROR") {
    InputBox, notesPath, Notes Inbox Path, Enter the path to your notes folder
    if ErrorLevel
        return
    IniWrite, %notesPath%, settings.ini, Environment, notes-path
}
StringReplace, notesPath, notesPath, ~, %vUserProfile%, All

GuiCount := 1

; Enhanced note hotkey (replaces quick note)
^Numpad4::
Gosub, ShowEnhancedNote
return

ShowEnhancedNote:
CurrentGui := GuiCount
Start%CurrentGui% := A_TickCount

Gui, %CurrentGui%:New
Gui, %CurrentGui%:Font, s10

; Timer display (replaces Content label)
Gui, %CurrentGui%:Add, Text, x20 y15 w200 vTimer%CurrentGui%, Write time: 0s

; Main content
Gui, %CurrentGui%:Add, Edit, x20 y35 w800 h490 vNote WantTab VScroll, %Clipboard%

; Action buttons  
Gui, %CurrentGui%:Add, Button, x600 y535 w100 h35 gSaveNote, Save Note
Gui, %CurrentGui%:Add, Button, x710 y535 w90 h35 gCancelNote, Cancel

Gui, %CurrentGui%:Show, w820 h585, Quick Note
SetTimer, UpdateAllTimers, 1000
GuiCount := GuiCount + 1
return

; Single timer function that handles all GUIs
UpdateAllTimers:
Loop, %GuiCount% {
    guiNum := A_Index
    if (Start%guiNum% != "") {
        startTime := Start%guiNum%
        elapsed := Round((A_TickCount - startTime)/1000, 0)
        hours := Floor(elapsed / 3600)
        minutes := Floor((elapsed - hours * 3600) / 60)
        seconds := Mod(elapsed, 60)
        if (hours > 0) {
            timeText := hours . "h " . minutes . "m " . seconds . "s"
        } else if (minutes > 0) {
            timeText := minutes . "m " . seconds . "s"
        } else {
            timeText := seconds . "s"
        }
        GuiControl, %guiNum%:, Timer%guiNum%, Write time: %timeText%
    }
}
return

SaveNote:
; Mark this GUI as stopped by clearing its start time
Start%A_Gui% := ""
Gui, Submit
Gosub, ProcessNote
return

CancelNote:
; Mark this GUI as stopped by clearing its start time
Start%A_Gui% := ""
Gui, Destroy
return

ProcessNote:
startTime := Start%A_Gui%
Duration := Round((A_TickCount - startTime)/1000, 0)
Hours := Floor(Duration / 3600)
Minutes := Floor((Duration - Hours * 3600) / 60)
Seconds := Mod(Duration, 60)

if (Hours > 0) {
    DurationText := Hours . "h " . Minutes . "m " . Seconds . "s"
} else if (Minutes > 0) {
    DurationText := Minutes . "m " . Seconds . "s"
} else {
    DurationText := Seconds . "s"
}

finalNote := Note

; Extract title from first line of content (always automated)
noteTitle := ""
if (finalNote != "") {
    Loop, Parse, finalNote, `n, `r
    {
        firstLine := Trim(A_LoopField)
        if (firstLine != "") {
            ; Remove markdown header symbols
            if (SubStr(firstLine, 1, 4) = "### ") {
                noteTitle := Trim(SubStr(firstLine, 5))
            } else if (SubStr(firstLine, 1, 3) = "## ") {
                noteTitle := Trim(SubStr(firstLine, 4))
            } else if (SubStr(firstLine, 1, 2) = "# ") {
                noteTitle := Trim(SubStr(firstLine, 3))
            } else {
                noteTitle := firstLine
            }
            break
        }
    }
}

; Create clean filename from title
fileName := A_YYYY . A_MM . A_DD . "T" . A_Hour . A_Min . A_Sec
if (noteTitle != "") {
    title := noteTitle
    StringLower, title, title
    StringReplace, title, title, %A_Space%, -, All
    ; Remove any characters that aren't alphanumeric, hyphens, or underscores
    title := RegExReplace(title, "[^a-z0-9\-_]", "")
    if (title != "") {
        fileName := fileName . "_" . title
    }
}

; Generate short hash for unique identifier
hashSource := StrLen(finalNote) . A_TickCount . A_MSec
Random, randNum, 1000, 9999
hashSource .= randNum

shortHash := ""
Loop, 8 {
    Random, hexDigit, 0, 15
    if (hexDigit < 10) {
        shortHash .= hexDigit
    } else {
        shortHash .= Chr(87 + hexDigit)
    }
}

fileName := fileName . "_" . shortHash

; Calculate word count and reading time
wordCount := 0
Loop, Parse, finalNote, %A_Space%%A_Tab%`n`r
{
    if (A_LoopField != "") {
        wordCount++
    }
}

readingTimeMinutes := wordCount / 225
readingTimeSeconds := Round(readingTimeMinutes * 60, 0)
readingHours := Floor(readingTimeSeconds / 3600)
readingMins := Floor((readingTimeSeconds - readingHours * 3600) / 60)
readingSecs := Mod(readingTimeSeconds, 60)

if (readingHours > 0) {
    readTimeText := readingHours . "h " . readingMins . "m " . readingSecs . "s"
} else if (readingMins > 0) {
    readTimeText := readingMins . "m " . readingSecs . "s"
} else {
    readTimeText := readingSecs . "s"
}

; Create enhanced YAML front-matter
createdDate := A_YYYY . "-" . A_MM . "-" . A_DD
createdTime := A_Hour . ":" . A_Min . ":" . A_Sec
createdDateTime := createdDate . "T" . createdTime

frontMatter := "---`n"
if (noteTitle != "") {
    ; Clean title for YAML frontmatter - remove colons and other problematic characters
    cleanTitle := noteTitle
    StringReplace, cleanTitle, cleanTitle, :, -, All
    StringReplace, cleanTitle, cleanTitle, ", ', All
    StringReplace, cleanTitle, cleanTitle, `, , -, All
    cleanTitle := RegExReplace(cleanTitle, "[#\[\]{}|>]", "")
    cleanTitle := Trim(cleanTitle)
    frontMatter .= "title: " . cleanTitle . "`n"
}
frontMatter .= "created: " . createdDateTime . "`n"
frontMatter .= "write_time: " . DurationText . "`n"
frontMatter .= "read_time: " . readTimeText . "`n"
frontMatter .= "word_count: " . wordCount . "`n"
frontMatter .= "id: " . shortHash . "`n"
frontMatter .= "---`n`n"

finalNote := frontMatter . finalNote
FileAppend, %finalNote%, %notesPath%\%fileName%.md

MsgBox, 64, Note Saved, Note saved successfully as %fileName%.md
return

CancelEnhanced:
EnhancedGuiClose:
EnhancedGuiEscape:
; Mark this GUI as stopped by clearing its start time
Start%A_Gui% := ""
Gui, Destroy
return

GuiEscape:
GuiClose:
; Mark this GUI as stopped by clearing its start time
Start%A_Gui% := ""
Gui, Destroy
return