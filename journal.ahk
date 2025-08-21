#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
EnvGet, vUserProfile, USERPROFILE
Menu, Tray, Icon, file-text.ico
Menu, Tray, Tip, Daily Journal

; Get journal path from settings or prompt user
IniRead, journalPath, settings.ini, Environment, journal-path
if (journalPath="ERROR") {
    journalPath = ~\org\notes\journal
    IniWrite, %journalPath%, settings.ini, Environment, journal-path
}
StringReplace, journalPath, journalPath, ~, %vUserProfile%, All

; Create journal directory if it doesn't exist
FileCreateDir, %journalPath%

; Set up daily timer for 15:00 (3:00 PM)
currentTime := A_Hour * 3600 + A_Min * 60 + A_Sec
targetTime := 15 * 3600
secondsUntilTarget := targetTime - currentTime

if (secondsUntilTarget <= 0) {
    secondsUntilTarget += 24 * 3600
}

millisecondsUntilTarget := secondsUntilTarget * 1000
SetTimer, ShowJournalPrompt, %millisecondsUntilTarget%

return

ShowJournalPrompt:
SetTimer, ShowJournalPrompt, 86400000

Gui, Add, Text, x20 y20 w560 Center, Daily Journal Time - 3:00 PM Reflection
Gui, Add, Text, x20 y50 w560 Center c666666, Write two sentences about your day
Gui, Add, Text, x20 y90 w560, What happened today?
Gui, Add, Edit, x20 y110 w560 h60 vSentence1 WantReturn
Gui, Add, Text, x20 y180 w560, What are your thoughts on this?
Gui, Add, Edit, x20 y200 w560 h60 vSentence2 WantReturn
Gui, Add, Button, x20 y280 w120 h40 gSaveEntry, Save Entry
Gui, Add, Button, x160 y280 w120 h40 gSkipEntry, Skip Today
Gui, Add, Button, x300 y280 w120 h40 gRemindLater, Remind Later
Gui, Add, Button, x460 y280 w120 h40 gCloseGui, Cancel
Gui, Show, w600 h340, Daily Journal Entry
return

SaveEntry:
Gui, Submit
if (Sentence1 = "" || Sentence2 = "") {
    MsgBox, 48, Incomplete Entry, Please write both sentences for your journal entry.
    Gosub, ShowJournalPrompt
    return
}

fileName := A_YYYY . A_MM . A_DD . "T" . A_Hour . A_Min . A_Sec
journalEntry := "# Daily Journal - " . A_YYYY . "-" . A_MM . "-" . A_DD . "`n`n"
journalEntry .= Sentence1 . " " . Sentence2 . "`n`n"
journalEntry .= "*Written at " . A_Hour . ":" . A_Min . " on " . A_YYYY . "-" . A_MM . "-" . A_DD . "*"
fullPath := journalPath . "\" . fileName . ".md"
FileAppend, %journalEntry%, %fullPath%
MsgBox, 64, Journal Saved, Your journal entry has been saved successfully!
return

SkipEntry:
Gui, Destroy
MsgBox, 64, Entry Skipped, No journal entry saved for today. See you tomorrow at 3 PM!
return

RemindLater:
Gui, Destroy
SetTimer, ShowJournalPrompt, 1800000
MsgBox, 64, Reminder Set, I will remind you again in 30 minutes.
return

CloseGui:
GuiClose:
GuiEscape:
Gui, Destroy
return

^+j::
Gosub, ShowJournalPrompt
return