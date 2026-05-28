#Requires AutoHotkey v2.0

; Daily Journal Prompt
; Scheduled journal prompts and thought capture with robust timing

SetupConfig()
SetTrayTip()

; Global state
journalPromptShown := false
thoughtPromptScheduled := ""
journalGuiActive := false
thoughtGuiActive := false
lastCheckTime := A_Now

; Check for scheduled prompts immediately on startup
CheckForThoughtPrompt()
ScheduleNextThoughtPrompt()
UpdateTrayTip()

; Timers for checking prompts
SetTimer(CheckForThoughtPrompt, 60000)

/**
 * Check if it's time for the daily journal prompt (3 PM)
 * Journal only prompts once per day between 9 AM and 5 PM
 */
CheckForJournalTime() {
    global journalPromptShown, journalGuiActive, lastCheckTime, journalPath
    
    currentTime := A_Now
    currentHour := Integer(SubStr(currentTime, 9, 2))
    
    ; Detect system wake from sleep (gap > 5 minutes)
    timeDiff := DateDiff(lastCheckTime, currentTime, "s")
    if (timeDiff > 300) {
        ; Check if we crossed into a new day during sleep
        lastPromptDate := IniRead(A_ScriptDir . "\settings.ini", "Journal", "last-prompt-date", "")
        todayKey := FormatTime(A_Now, "yyyyMMdd")
        if (lastPromptDate != todayKey) {
            journalPromptShown := false
            UpdateTrayTip()  ; Update tray when new day detected
        }
    }
    
    ; Only show prompt during waking hours (9 AM - 5 PM)
    ; Show prompt at 3 PM if not already shown and GUI not active
    if (currentHour >= 15 && currentHour < 17 && !journalPromptShown && !journalGuiActive) {
        ShowJournalPrompt()
    }
    
    ; Reset flag at midnight for next day
    if (currentHour = 0 && journalPromptShown) {
        journalPromptShown := false
        UpdateTrayTip()  ; Update tray at midnight
    }
    
    lastCheckTime := currentTime
}

/**
 * Check if it's time for scheduled thought prompt
 */
CheckForThoughtPrompt() {
    global thoughtPromptScheduled, thoughtGuiActive, journalGuiActive
    
    if (thoughtPromptScheduled = "" || thoughtGuiActive || journalGuiActive)
        return
    
    currentTime := A_Now
    if (currentTime >= thoughtPromptScheduled) {
        ShowThoughtPrompt()
        ScheduleNextThoughtPrompt()
    }
}

/**
 * Schedule next random thought prompt during waking hours (9 AM - 5 PM)
 * Thought capture can happen multiple times per day
 */
ScheduleNextThoughtPrompt() {
    global thoughtPromptScheduled
    
    currentHour := Integer(SubStr(A_Now, 9, 2))
    
    ; If past 5 PM or before 9 AM, schedule for tomorrow at 9 AM
    if (currentHour >= 17 || currentHour < 9) {
        tomorrow := DateAdd(A_Now, 1, "d")
        thoughtPromptScheduled := FormatTime(tomorrow, "yyyyMMdd") . "090000"
    } else {
        ; Random time between 1-3 hours from now
        minutesOffset := Random(60, 180)
        nextTime := DateAdd(A_Now, minutesOffset, "m")
        nextHour := Integer(SubStr(nextTime, 9, 2))
        
        if (nextHour >= 17) {
            ; If it goes past 5 PM, schedule for tomorrow 9 AM instead
            tomorrow := DateAdd(A_Now, 1, "d")
            thoughtPromptScheduled := FormatTime(tomorrow, "yyyyMMdd") . "090000"
        } else {
            thoughtPromptScheduled := nextTime
        }
    }
    
    UpdateTrayTip()  ; Update tray with new schedule
    
    displayTime := FormatTime(thoughtPromptScheduled, "HH:mm")
    TrayTip("Next thought prompt at: " displayTime, "Thought Capture Scheduled", 1)
}

ShowJournalPrompt() {
    global journalGuiActive, journalPromptShown, journalPath, thoughtLogsPath
    
    journalGuiActive := true
    
    MyGui := Gui()
    MyGui.Add("Text", "x20 y20 w560 Center", "Daily Journal - 3:00 PM Reflection")
    MyGui.Add("Text", "x20 y50 w560 Center c666666", "Write two sentences about your day")
    MyGui.Add("Text", "x20 y90 w560", "What happened today?")
    MyGui.Add("Edit", "x20 y110 w560 h60 vSentence1", "")
    MyGui.Add("Text", "x20 y180 w560", "What are your thoughts on this?")
    MyGui.Add("Edit", "x20 y200 w560 h60 vSentence2", "")
    MyGui.Add("Button", "x20 y280 w120 h40", "Save Entry").OnEvent("Click", SaveEntry)
    MyGui.Add("Button", "x160 y280 w120 h40", "Skip Today").OnEvent("Click", SkipEntry)
    MyGui.Add("Button", "x300 y280 w120 h40", "Remind Later").OnEvent("Click", RemindLater)
    MyGui.Add("Button", "x460 y280 w120 h40", "Cancel").OnEvent("Click", CloseGui)
    
    MyGui.OnEvent("Close", CloseGui)
    MyGui.OnEvent("Escape", CloseGui)
    MyGui.Title := "Daily Journal Entry"
    MyGui.Show("w600 h340")
}

SaveEntry(GuiCtrlObj, Info) {
    global journalGuiActive, journalPromptShown, journalPath
    
    MyGui := GuiCtrlObj.Gui
    saved := MyGui.Submit(false)  ; Don't hide yet, validate first
    
    sentence1 := saved.Sentence1
    sentence2 := saved.Sentence2
    
    if (sentence1 = "" || sentence2 = "") {
        MsgBox("Please complete both sentences", "Incomplete Entry", 48)
        return
    }
    
    try {
        journalPromptShown := true
        journalGuiActive := false
        
        todayKey := FormatTime(A_Now, "yyyyMMdd")
        IniWrite(todayKey, A_ScriptDir . "\settings.ini", "Journal", "last-prompt-date")
        
        fileName := FormatTime(A_Now, "yyyyMMddTHHmmss")
        journalEntry := "# Daily Journal - " . FormatTime(A_Now, "yyyy-MM-dd") . "`n`n"
        journalEntry .= sentence1 . " " . sentence2 . "`n`n"
        journalEntry .= "*Written at " . FormatTime(A_Now, "HH:mm") . " on " . FormatTime(A_Now, "yyyy-MM-dd") . "*"
        
        FileAppend(journalEntry, journalPath . "\" . fileName . ".md", "UTF-8")
        MsgBox("Journal entry saved successfully!", "Success", 64)
        MyGui.Destroy()
        UpdateTrayTip()  ; Update tray after saving
    } catch as err {
        MsgBox("Error saving journal: " err.What, "Error", 48)
        journalGuiActive := false
    }
}

SkipEntry(GuiCtrlObj, Info) {
    global journalGuiActive, journalPromptShown
    
    try {
        journalPromptShown := true
        journalGuiActive := false
        
        todayKey := FormatTime(A_Now, "yyyyMMdd")
        IniWrite(todayKey, A_ScriptDir . "\settings.ini", "Journal", "last-prompt-date")
        
        GuiCtrlObj.Gui.Destroy()
        MsgBox("No journal entry saved. See you tomorrow at 3 PM!", "Skipped", 64)
        UpdateTrayTip()  ; Update tray after skipping
    } catch as err {
        journalGuiActive := false
    }
}

RemindLater(GuiCtrlObj, Info) {
    global journalGuiActive, journalPromptShown
    
    journalGuiActive := false
    journalPromptShown := false  ; Reset so it can prompt again later
    
    GuiCtrlObj.Gui.Destroy()
    MsgBox("I'll remind you again in 30 minutes", "Reminder Set", 64)
}

CloseGui(GuiCtrlObj, Info := "") {
    global journalGuiActive
    
    journalGuiActive := false
    ; Handle both button click (GuiCtrlObj.Gui) and direct GUI events (GuiCtrlObj)
    if (HasProp(GuiCtrlObj, "Gui"))
        GuiCtrlObj.Gui.Destroy()
    else
        GuiCtrlObj.Destroy()
}

ShowThoughtPrompt() {
    global thoughtGuiActive
    
    thoughtGuiActive := true
    
    MyGui := Gui()
    MyGui.Add("Text", "x20 y20 w560 Center", "Random Thought Capture")
    MyGui.Add("Text", "x20 y50 w560 Center c666666", "What are you thinking about right now?")
    MyGui.Add("Text", "x20 y80 w560", "How are you feeling?")
    MyGui.Add("Radio", "x20 y100 w110 vMoodGroup Group Checked", "Neutral")
    MyGui.Add("Radio", "x140 y100 w100", "Bored")
    MyGui.Add("Radio", "x250 y100 w110", "Excited")
    MyGui.Add("Radio", "x370 y100 w120", "Frustrated")
    MyGui.Add("Radio", "x20 y125 w100", "Tired")
    MyGui.Add("Text", "x20 y150 w560", "Mood details (optional):")
    MyGui.Add("Edit", "x20 y170 w560 h24 vMoodFreeform", "")
    MyGui.Add("Edit", "x20 y205 w560 h85 vThoughtText", "")
    MyGui.Add("Button", "x20 y295 w180 h40", "Save Thought").OnEvent("Click", SaveThought)
    MyGui.Add("Button", "x220 y295 w180 h40", "Dismiss").OnEvent("Click", DismissThought)
    MyGui.Add("Button", "x420 y295 w160 h40", "Cancel").OnEvent("Click", CloseThoughtGui)
    
    MyGui.OnEvent("Close", CloseThoughtGui)
    MyGui.OnEvent("Escape", CloseThoughtGui)
    MyGui.Title := "Thought Capture"
    MyGui.Show("w600 h355")
}

SaveThought(GuiCtrlObj, Info) {
    global thoughtGuiActive, thoughtLogsPath
    
    MyGui := GuiCtrlObj.Gui
    saved := MyGui.Submit(false)  ; Don't hide yet, validate first
    
    thoughtText := saved.ThoughtText
    
    if (thoughtText = "") {
        MsgBox("Please write something or dismiss the prompt", "Empty Thought", 48)
        return
    }
    
    try {
        thoughtGuiActive := false
        
        moods := ["Neutral", "Bored", "Excited", "Frustrated", "Tired"]
        moodIndex := saved.MoodGroup
        moodName := (moodIndex >= 1 && moodIndex <= moods.Length) ? moods[moodIndex] : "Neutral"
        moodFreeform := Trim(saved.MoodFreeform)
        
        fileName := FormatTime(A_Now, "yyyyMMddTHHmmss")
        thoughtEntry := "# Thought Log - " . FormatTime(A_Now, "yyyy-MM-dd") . " " . FormatTime(A_Now, "HH:mm") . "`n`n"
        thoughtEntry .= "**Mood:** " . moodName . "`n`n"
        if (moodFreeform != "")
            thoughtEntry .= "**Mood Details:** " . moodFreeform . "`n`n"
        thoughtEntry .= thoughtText . "`n`n"
        thoughtEntry .= "*Captured at " . FormatTime(A_Now, "HH:mm") . " on " . FormatTime(A_Now, "yyyy-MM-dd") . "*"
        
        FileAppend(thoughtEntry, thoughtLogsPath . "\" . fileName . ".md", "UTF-8")
        MsgBox("Thought captured!", "Saved", 64)
        MyGui.Destroy()
        ScheduleNextThoughtPrompt()
    } catch as err {
        MsgBox("Error saving thought: " err.What, "Error", 48)
        thoughtGuiActive := false
    }
}

DismissThought(GuiCtrlObj, Info) {
    global thoughtGuiActive
    
    thoughtGuiActive := false
    GuiCtrlObj.Gui.Destroy()
    ScheduleNextThoughtPrompt()
}

CloseThoughtGui(GuiCtrlObj, Info := "") {
    global thoughtGuiActive
    
    thoughtGuiActive := false
    ; Handle both button click (GuiCtrlObj.Gui) and direct GUI events (GuiCtrlObj)
    if (HasProp(GuiCtrlObj, "Gui"))
        GuiCtrlObj.Gui.Destroy()
    else
        GuiCtrlObj.Destroy()
}

SetupConfig() {
    global journalPath, thoughtLogsPath
    
    userProfile := EnvGet("USERPROFILE")
    journalPathConfig := IniRead(A_ScriptDir . "\settings.ini", "Environment", "journal-path", "")
    thoughtLogsPathConfig := IniRead(A_ScriptDir . "\settings.ini", "Environment", "thought-logs-path", "")
    
    if (journalPathConfig = "") {
        journalPathConfig := "~\org\notes\80 System\journal-logs"
        IniWrite(journalPathConfig, A_ScriptDir . "\settings.ini", "Environment", "journal-path")
    }
    
    if (thoughtLogsPathConfig = "") {
        thoughtLogsPathConfig := "~\org\notes\80 System\thought-logs"
        IniWrite(thoughtLogsPathConfig, A_ScriptDir . "\settings.ini", "Environment", "thought-logs-path")
    }
    
    journalPath := StrReplace(journalPathConfig, "~", userProfile)
    thoughtLogsPath := StrReplace(thoughtLogsPathConfig, "~", userProfile)
    
    try {
        DirCreate(journalPath)
        DirCreate(thoughtLogsPath)
    }
}

SetTrayTip() {
    try {
        A_TrayMenu.SetIcon(A_ScriptDir . "\file-text.ico", 1)
    }
    A_TrayMenu.Tip := "Thought Capture"
}

/**
 * Update tray tooltip with thought prompt schedule
 */
UpdateTrayTip() {
    global thoughtPromptScheduled
    
    todayKey := FormatTime(A_Now, "yyyyMMdd")
    
    ; Add thought prompt schedule
    thoughtMsg := ""
    if (thoughtPromptScheduled != "") {
        thoughtTime := FormatTime(thoughtPromptScheduled, "HH:mm")
        thoughtDate := FormatTime(thoughtPromptScheduled, "yyyyMMdd")
        if (thoughtDate = todayKey) {
            thoughtMsg := "`nNext thought: Today " . thoughtTime
        } else {
            thoughtMsg := "`nNext thought: Tomorrow " . thoughtTime
        }
    }
    
    if (thoughtMsg != "") {
        A_TrayMenu.Tip := "Thought capture" . thoughtMsg
    } else {
        A_TrayMenu.Tip := "Thought capture"
    }
}
