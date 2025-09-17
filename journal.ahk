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

; Initialize variables for reliable daily prompts
lastCheckTime := A_Now
promptShownToday := false
guiActive := false  ; Flag to track if GUI is currently shown
todayDateKey := A_YYYY . A_MM . A_DD

; Check if we already showed prompt today (in case of script restart)
IniRead, lastPromptDate, settings.ini, Journal, last-prompt-date
if (lastPromptDate = todayDateKey) {
    promptShownToday := true
}

; Check immediately if we missed today's 15:00 prompt
Gosub, CheckForJournalTime

; Set up timer to check every minute for 15:00
SetTimer, CheckForJournalTime, 60000

return

CheckForJournalTime:
currentTime := A_Now
todayDateKey := A_YYYY . A_MM . A_DD
currentHour := A_Hour + 0
currentMinute := A_Min + 0

; Detect if system was asleep (more than 5 minutes since last check)
timeDiff := currentTime
timeDiff -= lastCheckTime, Seconds
if (timeDiff > 300) {  ; More than 5 minutes gap indicates sleep/suspend
    ; Reset prompt flag if we crossed into a new day during sleep
    IniRead, lastPromptDate, settings.ini, Journal, last-prompt-date
    if (lastPromptDate != todayDateKey) {
        promptShownToday := false
    }
}

; Check if it's time for the journal prompt (15:00 or later, but before 23:59)
; Only trigger if GUI is not already active
if (currentHour >= 15 && !promptShownToday && !guiActive) {
    ; Don't set promptShownToday here - only set it after user interaction
    Gosub, ShowJournalPrompt
}

; Reset flag at midnight for next day
if (currentHour = 0 && currentMinute < 2 && promptShownToday) {
    promptShownToday := false
}

lastCheckTime := currentTime
return

ShowJournalPrompt:
; Destroy any existing GUI first
Gui, Destroy

; Set flag to indicate GUI is now active
guiActive := true

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

; Mark as completed for today only after successful save
promptShownToday := true
guiActive := false  ; Clear GUI active flag
todayDateKey := A_YYYY . A_MM . A_DD
IniWrite, %todayDateKey%, settings.ini, Journal, last-prompt-date

fileName := A_YYYY . A_MM . A_DD . "T" . A_Hour . A_Min . A_Sec
journalEntry := "# Daily Journal - " . A_YYYY . "-" . A_MM . "-" . A_DD . "`n`n"
journalEntry .= Sentence1 . " " . Sentence2 . "`n`n"
journalEntry .= "*Written at " . A_Hour . ":" . A_Min . " on " . A_YYYY . "-" . A_MM . "-" . A_DD . "*"
fullPath := journalPath . "\" . fileName . ".md"
FileAppend, %journalEntry%, %fullPath%
MsgBox, 64, Journal Saved, Your journal entry has been saved successfully!
return

SkipEntry:
; Mark as completed for today only after user chooses to skip
promptShownToday := true
guiActive := false  ; Clear GUI active flag
todayDateKey := A_YYYY . A_MM . A_DD
IniWrite, %todayDateKey%, settings.ini, Journal, last-prompt-date

Gui, Destroy
MsgBox, 64, Entry Skipped, No journal entry saved for today. See you tomorrow at 3 PM!
return

RemindLater:
Gui, Destroy
guiActive := false  ; Clear GUI active flag
; Reset the flag so CheckForJournalTime can trigger again
promptShownToday := false
; Remove the conflicting timer - let CheckForJournalTime handle the next prompt
MsgBox, 64, Reminder Set, I will remind you again in 30 minutes.
return

CloseGui:
GuiClose:
GuiEscape:
Gui, Destroy
guiActive := false  ; Clear GUI active flag
return

^+j::
Gosub, ShowJournalPrompt
return