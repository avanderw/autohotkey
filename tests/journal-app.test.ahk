#Requires AutoHotkey v2.0

assertions := 0

Assert(actual, expected, label) {
    global assertions
    assertions += 1
    if (actual != expected)
        throw Error(label . ": expected " . expected . ", got " . actual)
}

testFolder := A_Temp . "\Self-Check-In app tests " . DllCall("GetCurrentProcessId") . Chr(0x03A9)
originalLocalAppData := EnvGet("LOCALAPPDATA")
startupTestKey := "HKCU\Software\Self-Check-In\Tests-" . DllCall("GetCurrentProcessId")
try {
    EnvSet("LOCALAPPDATA", testFolder)
    DirCreate(testFolder . "\ThoughtCapture")
    settingsPath := testFolder . "\ThoughtCapture\settings.ini"
    IniWrite(testFolder . "\notes", settingsPath, "Environment", "notes-path")
    IniWrite("broken", settingsPath, "Schedule", "start-hour")
    IniWrite(7, settingsPath, "Schedule", "end-hour")
    IniWrite(300, settingsPath, "Schedule", "minimum-minutes")
    IniWrite(10, settingsPath, "Schedule", "maximum-minutes")
    IniWrite("broken", settingsPath, "ThoughtCaptureUsage", "energy-1")
    IniWrite(1, settingsPath, "Journal", "enabled")
    legacySettingsPath := settingsPath
    IniWrite("20990101090000", legacySettingsPath, "Schedule", "next-due")
    SetupConfig(false)
    Assert(settingsPath, testFolder . "\Self-Check-In\settings.ini", "Renamed settings folder")
    Assert(FileExist(legacySettingsPath) != "", true, "Legacy configuration preserved")
    Assert(IniRead(settingsPath, "Schedule", "next-due"), "20990101090000", "Migration preserves due time")
    IniWrite(1, settingsPath, "Schedule", "weekends")
    IniWrite(0, legacySettingsPath, "Schedule", "weekends")
    SetupConfig(false)
    Assert(weekends, 1, "Existing new settings are not overwritten")
    RegWrite('"C:\old\ThoughtCapture.exe"', "REG_SZ", startupTestKey, "ThoughtCapture")
    MigrateStartupRegistration(startupTestKey)
    Assert(RegRead(startupTestKey, "Self-Check-In"), StartupCommand(), "Startup migrated to current executable")
    Assert(RegRead(startupTestKey, "ThoughtCapture", ""), "", "Old startup entry removed")
    RegWrite('"C:\keep\Self-Check-In.exe"', "REG_SZ", startupTestKey, "Self-Check-In")
    RegWrite('"C:\old\ThoughtCapture.exe"', "REG_SZ", startupTestKey, "ThoughtCapture")
    MigrateStartupRegistration(startupTestKey)
    Assert(RegRead(startupTestKey, "Self-Check-In"), '"C:\keep\Self-Check-In.exe"', "Existing new startup registration preserved")
    Assert(DirExist(testFolder . "\notes\journal-logs"), "", "No daily journal folder")
    Assert(thoughtLogsPath, testFolder . "\notes\logs", "One logs output folder")
    Assert(DirExist(testFolder . "\notes\thought-logs"), "", "No old thought-logs folder created")
    Assert(startHour, 9, "Recover malformed hours")
    Assert(endHour, 17, "Recover reversed hours")
    Assert(maximumMinutes >= minimumMinutes, true, "Recover reversed interval")
    Assert(GetMostUsedIndex("energy", 3, 2), 2, "Recover malformed usage counter")
    thoughtGuiActive := false
    thoughtWindow := ""
    settingsWindow := ""
    thoughtPromptScheduled := ""
    paused := false
    appVersion := "test"
    SetTrayTip()
    ScheduleNextThoughtPrompt()
    Assert(IniRead(settingsPath, "Schedule", "next-due"), thoughtPromptScheduled, "Persist schedule")
    paused := true
    Assert(CanPrompt(), false, "Paused reminders")
    Assert(InStr(StartupGuidance(), "paused") > 0, true, "Startup explains paused reminders")
    paused := false
    Assert(InStr(StartupGuidance(), "Next reminder:") > 0, true, "Startup states next reminder")
    Assert(InStr(StartupGuidance(), "Capture now") > 0, true, "Startup gives a next action")
    Assert(InStr(StartupGuidance(), "Self-Check-In") > 0, true, "Renamed startup guidance")
    ShowThoughtPrompt()
    Assert(thoughtGuiActive, true, "Prompt active")
    Assert(thoughtWindow.Title, "Self-Check-In", "Renamed capture window")
    firstWindow := thoughtWindow.Hwnd
    ShowThoughtPrompt()
    Assert(thoughtWindow.Hwnd, firstWindow, "No duplicate window")
    WinGetClientPos(, , &parentWidth, , thoughtWindow.Hwnd)
    WinGetPos(, , &panelWidth, , thoughtForm.Hwnd)
    Assert(panelWidth <= parentWidth, true, "Scroll panel and scrollbar fit within window")
    thoughtForm["EnergyGroup"].GetPos(&batteryLeft, &batteryTop)
    thoughtForm["FocusGroup"].GetPos(&attentionLeft, &attentionTop)
    Assert(batteryTop, attentionTop, "Battery and attention share a row")
    Assert(attentionLeft > batteryLeft, true, "Attention is beside battery")
    thoughtForm["Mood1"].GetPos(, &firstMoodTop)
    thoughtForm["Mood4"].GetPos(, &nextMoodTop)
    Assert(nextMoodTop - firstMoodTop, 22, "Compact mood row spacing")
    thoughtForm["Body1"].GetPos(, &firstBodyTop)
    thoughtForm["Body4"].GetPos(, &nextBodyTop)
    Assert(nextBodyTop - firstBodyTop, 22, "Short body labels use compact rows")
    Assert(thoughtScroll.ContentHeight <= thoughtScroll.ViewportHeight, true, "Whole form fits without scrolling on test display")
    Assert((WinGetStyle(thoughtForm.Hwnd) & 0x200000) = 0, true, "No unnecessary vertical scrollbar")
    thoughtForm["ActivityGroup"].GetPos(&activityLeft, &activityTop)
    thoughtForm["ImprovementGroup"].GetPos(&improvementLeft, &improvementTop)
    Assert(activityTop, improvementTop, "Activity and next action share a row")
    Assert(improvementLeft > activityLeft, true, "Next action is beside activity")
    Assert(InStr(WinGetText("ahk_id " . thoughtWindow.Hwnd), "Current context"), 0, "No context question")
    Assert(thoughtForm["Body1"].Text, "Tense / tight", "Short tension label")
    Assert(thoughtForm["Body2"].Text, "At ease / relaxed", "Short ease label")
    for index, label in CaptureOptions().Body
        Assert(thoughtForm["Body" . index].Text, label, "Body display matches stored option " . index)
    thoughtForm["ThoughtText"].GetPos(, , &reflectionWidth)
    Assert(reflectionWidth, 432, "Wider reflection textbox")
    thoughtForm["ActivityHeading"].GetPos(, &activityHeadingTop)
    Assert(activityTop - activityHeadingTop, batteryTop - 14, "Activity input matches first-row spacing")
    thoughtForm["ImprovementHeading"].GetPos(, &improvementHeadingTop)
    Assert(improvementTop - improvementHeadingTop, batteryTop - 14, "Action input matches first-row spacing")
    for headingName in ["BatteryHeading", "AttentionHeading", "MoodHeading", "BodyHeading", "ActivityHeading", "ImprovementHeading", "HeadlineHeading"] {
        font := SendMessage(0x31, 0, 0, thoughtForm[headingName].Hwnd)
        fontInfo := Buffer(92, 0)
        DllCall("gdi32\GetObjectW", "Ptr", font, "Int", 92, "Ptr", fontInfo)
        Assert(NumGet(fontInfo, 16, "Int") >= 700, true, headingName . " is bold")
    }
    Assert(thoughtScroll.Hints[thoughtForm["Headline"].Hwnd], HeadlineGuidance(), "Headline input has past-hours guidance")
    Assert(thoughtScroll.Hints[thoughtForm["HeadlineHeading"].Hwnd], HeadlineGuidance(), "Headline label has past-hours guidance")
    Critical("On")
    try {
        CaptureHover(0, 0, 0x200, thoughtForm["Headline"].Hwnd)
        Assert(WinExist("ahk_class tooltips_class32") != 0, true, "Headline hover displays a tooltip")
        ClearCaptureHint()
    } finally {
        Critical("Off")
    }
    Assert(InStr(thoughtForm["ReflectionGuidance"].Text, "A kind message to myself?") > 0, true, "Short supportive reflection prompt")
    initialValues := thoughtForm.Submit(false)
    Assert(initialValues.EnergyGroup, 3, "New battery default")
    Assert(initialValues.FocusGroup, 1, "New attention default")
    nextControl := DllCall("GetNextDlgTabItem", "Ptr", thoughtWindow.Hwnd, "Ptr", thoughtForm["EnergyGroup"].Hwnd, "Int", false, "Ptr")
    Assert(nextControl, thoughtForm["FocusGroup"].Hwnd, "Keyboard Tab moves battery to attention")
    footerControl := DllCall("GetNextDlgTabItem", "Ptr", thoughtWindow.Hwnd, "Ptr", thoughtForm["ThoughtText"].Hwnd, "Int", false, "Ptr")
    Assert(footerControl, thoughtWindow["SaveThought"].Hwnd, "Keyboard Tab moves reflection to Save")
    thoughtForm["Mood1"].Value := 1
    thoughtForm["Mood11"].Value := 1
    thoughtForm["Body1"].Value := 1
    thoughtForm["Body5"].Value := 1
    thoughtForm["ActivityGroup"].Choose(5)
    thoughtForm["ImprovementGroup"].Choose(12)
    thoughtForm["Headline"].Value := "Testing"
    thoughtForm["ThoughtText"].Value := "A grateful thought " . Chr(0x03A9) . "`nAnother line"
    thoughtWindow["SaveThought"].GetPos(, &saveTop)
    fullViewportHeight := thoughtScroll.ViewportHeight
    thoughtScroll.ViewportHeight := 240
    SetCaptureScroll(10000)
    Assert(thoughtScroll.Offset, thoughtScroll.ContentHeight - thoughtScroll.ViewportHeight, "Scroll clamps at bottom")
    thoughtWindow["SaveThought"].GetPos(, &scrolledSaveTop)
    Assert(saveTop, scrolledSaveTop, "Save button stays fixed")
    SetCaptureScroll(-100)
    Assert(thoughtScroll.Offset, 0, "Scroll clamps at top")
    thoughtForm["ThoughtText"].Focus()
    KeepCaptureFocusVisible()
    Assert(thoughtScroll.Offset > 0, true, "Keyboard focus scrolls reflection into view")
    Assert(ControlGetVisible(thoughtForm["ThoughtText"].Hwnd), true, "Reflection stays accessible")
    tabsFound := 0
    for className in WinGetControls("ahk_id " . thoughtWindow.Hwnd) {
        if InStr(className, "SysTabControl")
            tabsFound += 1
    }
    Assert(tabsFound, 0, "No tab pages")
    CaptureVerticalScroll(6, 0, 0x115, thoughtForm.Hwnd)
    Assert(thoughtScroll.Offset, 0, "Scrollbar moves to top")
    CaptureMouseWheel(0xFF880000, 0, 0x20A, thoughtForm.Hwnd)
    Assert(thoughtScroll.Offset > 0, true, "Mouse wheel scrolls down")
    thoughtScroll.ViewportHeight := fullViewportHeight
    SetCaptureScroll(0)
    Assert(thoughtScroll.Offset, 0, "Full-size form needs no scrolling")
    SaveThought({Gui: thoughtWindow}, "")
    Assert(thoughtGuiActive, false, "Save closes prompt")
    notes := []
    Loop Files thoughtLogsPath . "\*.md"
        notes.Push(A_LoopFileFullPath)
    Assert(notes.Length, 1, "One saved note")
    text := FileRead(notes[1], "UTF-8")
    Assert(InStr(text, "# Self Check-in Log - "), 1, "Self check-in Markdown title")
    Assert(InStr(text, "Captured at"), 0, "No redundant timestamp footer")
    Assert(InStr(text, "A grateful thought " . Chr(0x03A9)) > 0, true, "Saved Unicode form content")
    Assert(InStr(text, "**Headline:** Testing") > 0, true, "Saved headline")
    Assert(IniRead(settingsPath, "ThoughtCaptureUsage", "battery-v2-3"), 1, "Persist new preference count")
    Assert(InStr(text, "**Battery:** Functional") > 0, true, "Saved battery")
    Assert(InStr(text, "**Attention:** It's sharp") > 0, true, "Saved attention")
    Assert(InStr(text, "**Mood:** Good; I don't know") > 0, true, "Save multiple moods")
    Assert(InStr(text, "**Body:** Tense / tight; Pain / discomfort") > 0, true, "Save displayed body values exactly")
    Assert(InStr(text, "**Activity:** Being creative") > 0, true, "Save selected activity")
    Assert(InStr(text, "**Context:**"), 0, "No context in saved note")
    Assert(InStr(text, "**Next Two Hours:** Say no") > 0, true, "Save last improvement option")
    ShowThoughtPrompt()
    CloseThoughtGui(thoughtWindow)
    Assert(thoughtGuiActive, false, "Close clears prompt flag")
    Assert(ValidTimestamp(IniRead(settingsPath, "Schedule", "next-due")), true, "Close persists next prompt")
    ShowThoughtPrompt()
    thoughtForm["ThoughtText"].Value := "Retain this after a failed save"
    oldFolder := thoughtLogsPath
    blockedFolder := testFolder . "\not-a-directory"
    FileAppend("blocking file", blockedFolder)
    thoughtLogsPath := blockedFolder
    SetTimer(DismissSaveError, -100)
    SaveThought({Gui: thoughtWindow}, "")
    Assert(thoughtGuiActive, true, "Failed save keeps prompt active")
    Assert(thoughtForm["ThoughtText"].Value, "Retain this after a failed save", "Failed save retains text")
    thoughtLogsPath := oldFolder
    CloseThoughtGui(thoughtWindow)
    ShowSettings()
    Assert(IsObject(settingsWindow), true, "Settings opens")
    Assert(InStr(WinGetText("ahk_id " . settingsWindow.Hwnd), "Daily journal"), 0, "No daily journal setting")
    CloseSettings()
    Assert(IsObject(settingsWindow), false, "Settings closes")
    FileAppend("PASS: " . assertions . " isolated application assertions`n", "*")
} catch as err {
    FileAppend("FAIL: " . err.Message . " (line " . err.Line . ")`n", "**")
    ExitApp(1)
} finally {
    if RegRead(startupTestKey, "Self-Check-In", "")
        RegDeleteKey(startupTestKey)
    EnvSet("LOCALAPPDATA", originalLocalAppData)
    if DirExist(testFolder)
        DirDelete(testFolder, true)
}
ExitApp(0)

DismissSaveError() {
    title := "Save failed ahk_pid " . DllCall("GetCurrentProcessId")
    if WinWait(title, , 3)
        WinClose(title)
}

#Include ..\journal.ahk