#Requires AutoHotkey v2.0
#SingleInstance Ignore
#Include journal-core.ahk
;@Ahk2Exe-SetName Self-Check-In
;@Ahk2Exe-SetDescription Self-Check-In reminders and local reflection logs
;@Ahk2Exe-SetVersion 1.0.0
;@Ahk2Exe-SetCompanyName Andrew van der Westhuizen
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Andrew van der Westhuizen

if (A_Args.Length && A_Args[1] = "--check")
    ExitApp(0)

thoughtPromptScheduled := ""
thoughtGuiActive := false
thoughtWindow := ""
thoughtForm := ""
thoughtScroll := ""
settingsWindow := ""
paused := false
appVersion := "1.0.0"

try {
    appMutex := DllCall("CreateMutexW", "Ptr", 0, "Int", false, "Str", "Local\ThoughtCapture", "Ptr")
    if !appMutex
        throw OSError()
    if (A_LastError = 183)
        ExitApp(0)
    OnExit(ConfirmExit)
    SetupConfig()
    if A_IsCompiled {
        try MigrateStartupRegistration()
        catch as err
            TrayTip("Could not update start-at-login registration: " . err.Message, "Self-Check-In")
    }
    paused := ReadNumber("Schedule", "paused", 0, 0, 1)
    thoughtPromptScheduled := IniRead(settingsPath, "Schedule", "next-due", "")
    if !ValidTimestamp(thoughtPromptScheduled)
        ScheduleNextThoughtPrompt()
    SetTrayTip()
    UpdateTrayTip()
    CheckForThoughtPrompt()
    if (A_Args.Length && A_Args[1] = "--capture")
        CaptureNow()
    if !thoughtGuiActive
        TrayTip(StartupGuidance(), "Self-Check-In is running")
    SetTimer(CheckForThoughtPrompt, 30000)
} catch as err {
    MsgBox("Self-Check-In could not start.`n`n" . err.Message, "Self-Check-In", 16)
    ExitApp(1)
}

CheckForThoughtPrompt() {
    global thoughtPromptScheduled, thoughtGuiActive
    if (thoughtPromptScheduled = "" || thoughtGuiActive || !CanPrompt())
        return
    if (A_Now >= thoughtPromptScheduled)
        ShowThoughtPrompt()
}

StartupGuidance() {
    global paused, thoughtPromptScheduled
    status := paused ? "Automatic reminders are paused."
        : "Next reminder: " . FormatTime(thoughtPromptScheduled, "ddd HH:mm") . "."
    return status . "`nRight-click the Self-Check-In tray icon and choose Capture now to begin. Use Settings to adjust reminders."
}

ScheduleNextThoughtPrompt() {
    global thoughtPromptScheduled, startHour, endHour, minimumMinutes, maximumMinutes, weekends, settingsPath
    thoughtPromptScheduled := NextThoughtTime(A_Now, Random(minimumMinutes, maximumMinutes), startHour, endHour, weekends)
    try IniWrite(thoughtPromptScheduled, settingsPath, "Schedule", "next-due")
    catch as err
        TrayTip("Schedule could not be saved: " . err.Message, "Self-Check-In")
    UpdateTrayTip()
}

CanPrompt() {
    global paused, startHour, endHour, weekends, settingsWindow
    now := A_Now
    if (paused || IsObject(settingsWindow) || ActiveTime(now, startHour, endHour, weekends) != now)
        return false
    desktop := DllCall("OpenInputDesktop", "UInt", 0, "Int", false, "UInt", 0x0100, "Ptr")
    if !desktop
        return false
    accessible := DllCall("SwitchDesktop", "Ptr", desktop)
    DllCall("CloseDesktop", "Ptr", desktop)
    return accessible
}

ConfirmExit(reason, code) {
    global thoughtGuiActive
    if thoughtGuiActive
        return MsgBox("A capture window is still open. Exit without saving?", "Self-Check-In", "YesNo Icon! Default2") = "No" ? 1 : 0
    return 0
}

^+d:: {
    CaptureNow()
}

CaptureOptions() {
    return {
        Energy: ["Fully charged", "Motivated", "Functional", "Low", "Drained"],
        Focus: ["It's sharp", "I'm daydreaming", "I feel scattered", "I'm foggy", "I'm done for the day"],
        Mood: ["Good", "Happy/Excited", "Content", "Irritable", "Frustrated/Annoyed/Angry", "Sad/Lonely",
            "Down/Depressed", "Anxious/Overwhelmed", "Hurt", "Numb", "I don't know"],
        Body: ["Tense / tight", "At ease / relaxed", "Restless / fidgety", "Heavy / sluggish / slow", "Pain / discomfort"],
        Activity: ["Working", "Procrastinating", "Relaxing", "Socialising", "Being creative"],
        Improvement: ["Drink water", "Move/Walk/Exercise", "Go outside/Fresh air/Nature", "Do a grounding activity",
            "Take a break", "Talk to someone", "Breathe", "Rest/Relax", "Do something creative",
            "Silence/Alone time", "Complete a task", "Say no"]
    }
}

AddChoice(window, name, options, selected, left, top, width) {
    return window.Add("DropDownList", "x" . left . " y" . top . " w" . width . " r8 AltSubmit v" . name . " Choose" . selected, options)
}

AddHeading(window, name, text, left, top, width) {
    heading := window.Add("Text", "x" . left . " y" . top . " w" . width . " h18 v" . name, text)
    heading.SetFont("bold")
    return heading
}

HeadlineGuidance() {
    return "If the past few hours were a news article, what would its one-word headline be?"
}

CaptureHover(wParam, lParam, message, hwnd) {
    global thoughtScroll
    if (!IsObject(thoughtScroll) || !thoughtScroll.Hints.Has(hwnd)) {
        ClearCaptureHint()
        return
    }
    ToolTip(thoughtScroll.Hints[hwnd], , , 3)
    SetTimer(ClearCaptureHint, -4000)
}

ClearCaptureHint() {
    ToolTip(, , , 3)
}

AddCheckboxOptions(window, name, options, left, top, columns, width, rowHeight := 28) {
    for index, label in options {
        horizontal := left + Mod(index - 1, columns) * width
        vertical := top + Floor((index - 1) / columns) * rowHeight
        window.Add("CheckBox", "x" . horizontal . " y" . vertical . " w" . (width - 8) . " h" . rowHeight
            . " +0x2000 v" . name . index, label)
    }
}

SelectedCheckboxes(options, saved, prefix) {
    selected := []
    for index, label in options {
        if saved.%prefix . index%
            selected.Push(label)
    }
    return selected.Length ? JoinItems(selected, "; ") : "None noted"
}

ShowThoughtPrompt(manual := false) {
    global thoughtGuiActive, thoughtWindow, thoughtForm, thoughtScroll
    static handlersRegistered := false
    if thoughtGuiActive
        return
    thoughtGuiActive := true
    options := CaptureOptions()
    MyGui := Gui("-MaximizeBox", "Self-Check-In")
    thoughtWindow := MyGui
    MyGui.SetFont("s9", "Segoe UI")
    DllCall("SetWindowLongPtr", "Ptr", MyGui.Hwnd, "Int", -20,
        "Ptr", DllCall("GetWindowLongPtr", "Ptr", MyGui.Hwnd, "Int", -20, "Ptr") | 0x10000, "Ptr")
    MonitorGetWorkArea(, , &workTop, , &workBottom)
    viewportHeight := Max(200, Min(446, Floor((workBottom - workTop) * 96 / A_ScreenDPI) - 100))
    form := Gui("-Caption +Parent" . MyGui.Hwnd . " +0x200000 +E0x10000")
    thoughtForm := form
    form.SetFont("s9", "Segoe UI")
    AddHeading(form, "BatteryHeading", "How is my battery level?", 18, 14, 306)
    AddHeading(form, "AttentionHeading", "Where is my attention landing right now?", 350, 14, 312)
    AddChoice(form, "EnergyGroup", options.Energy, GetMostUsedIndex("battery-v2", 5, 3), 18, 36, 306)
    AddChoice(form, "FocusGroup", options.Focus, GetMostUsedIndex("attention-v2", 5, 1), 350, 36, 312)
    AddHeading(form, "MoodHeading", "How am I feeling?", 18, 70, 644)
    AddCheckboxOptions(form, "Mood", options.Mood, 18, 92, 3, 216, 22)
    AddHeading(form, "BodyHeading", "How does my body feel?", 18, 190, 644)
    AddCheckboxOptions(form, "Body", options.Body, 18, 212, 3, 216, 22)
    AddHeading(form, "ActivityHeading", "What have I been doing?", 18, 266, 306)
    AddHeading(form, "ImprovementHeading", "What would improve the next two hours?", 350, 266, 312)
    AddChoice(form, "ActivityGroup", options.Activity, GetMostUsedIndex("activity", 5, 1), 18, 288, 306)
    AddChoice(form, "ImprovementGroup", options.Improvement, GetMostUsedIndex("improvement-v2", 12, 1), 350, 288, 312)
    headlineHeading := AddHeading(form, "HeadlineHeading", "One-word headline", 18, 326, 124)
    headlineInput := form.Add("Edit", "x150 y322 w512 h24 vHeadline", "")
    form.Add("Text", "x18 y362 w194 h60 c777777 vReflectionGuidance", "Grateful for right now?`nProud of myself for?`nA kind message to myself?")
    form.Add("Edit", "x230 y360 w432 h70 vThoughtText", "")
    positions := []
    for control in form {
        control.GetPos(, &top)
        positions.Push({Control: control, Top: top})
    }
    thoughtScroll := {Window: form, Offset: 0, ViewportHeight: viewportHeight, ContentHeight: 446, Controls: positions, LastFocus: 0,
        Hints: Map(headlineHeading.Hwnd, HeadlineGuidance(), headlineInput.Hwnd, HeadlineGuidance())}
    MyGui.Add("Button", "x18 y" . (viewportHeight + 14) . " w312 h36 Default vSaveThought", "Save Thought").OnEvent("Click", SaveThought)
    MyGui.Add("Button", "x350 y" . (viewportHeight + 14) . " w312 h36 vDismissThought", "Dismiss").OnEvent("Click", DismissThought)
    MyGui.OnEvent("Close", CloseThoughtGui)
    MyGui.OnEvent("Escape", CloseThoughtGui)
    form.OnEvent("Escape", (*) => CloseThoughtGui(MyGui))
    if !handlersRegistered {
        OnMessage(0x115, CaptureVerticalScroll)
        OnMessage(0x20A, CaptureMouseWheel)
        OnMessage(0x200, CaptureHover)
        handlersRegistered := true
    }
    panelWidth := 700 - Ceil(SysGet(2) * 96 / A_ScreenDPI)
    form.Show("x0 y0 w" . panelWidth . " h" . viewportHeight . " NoActivate")
    SetCaptureScroll(0)
    MyGui.Show("w700 h" . (viewportHeight + 68) . (manual ? "" : " NoActivate"))
    if manual
        form["EnergyGroup"].Focus()
    SetTimer(KeepCaptureFocusVisible, 75)
}

SetCaptureScroll(offset) {
    global thoughtScroll
    if !IsObject(thoughtScroll)
        return
    state := thoughtScroll
    state.LastFocus := DllCall("GetFocus", "Ptr")
    state.Offset := Max(0, Min(offset, state.ContentHeight - state.ViewportHeight))
    for item in state.Controls
        item.Control.Move(, item.Top - state.Offset)
    info := Buffer(28, 0)
    NumPut("UInt", 28, "UInt", 7, "Int", 0, "Int", state.ContentHeight - 1,
        "UInt", state.ViewportHeight, "Int", state.Offset, info)
    DllCall("SetScrollInfo", "Ptr", state.Window.Hwnd, "Int", 1, "Ptr", info, "Int", true)
}

CaptureVerticalScroll(wParam, lParam, message, hwnd) {
    global thoughtScroll
    if (!IsObject(thoughtScroll) || hwnd != thoughtScroll.Window.Hwnd || lParam)
        return
    state := thoughtScroll
    action := wParam & 0xFFFF
    switch action {
        case 0: offset := state.Offset - 32
        case 1: offset := state.Offset + 32
        case 2: offset := state.Offset - state.ViewportHeight
        case 3: offset := state.Offset + state.ViewportHeight
        case 4, 5:
            info := Buffer(28, 0)
            NumPut("UInt", 28, "UInt", 0x10, info)
            DllCall("GetScrollInfo", "Ptr", hwnd, "Int", 1, "Ptr", info)
            offset := NumGet(info, 24, "Int")
        case 6: offset := 0
        case 7: offset := state.ContentHeight
        default: return 0
    }
    SetCaptureScroll(offset)
    return 0
}

CaptureMouseWheel(wParam, lParam, message, hwnd) {
    global thoughtScroll, thoughtWindow
    if (!IsObject(thoughtScroll) || !IsObject(thoughtWindow)
        || (hwnd != thoughtWindow.Hwnd && !DllCall("IsChild", "Ptr", thoughtWindow.Hwnd, "Ptr", hwnd)))
        return
    className := WinGetClass(hwnd)
    if (className = "ComboBox" || className = "Edit")
        return
    delta := (wParam >> 16) & 0xFFFF
    if (delta > 32767)
        delta -= 65536
    SetCaptureScroll(thoughtScroll.Offset - Round(delta / 120 * 96))
    return 0
}

KeepCaptureFocusVisible() {
    global thoughtScroll, thoughtWindow
    if (!IsObject(thoughtScroll) || !IsObject(thoughtWindow))
        return
    focused := DllCall("GetFocus", "Ptr")
    if (!focused || !DllCall("IsChild", "Ptr", thoughtScroll.Window.Hwnd, "Ptr", focused))
        return
    if (focused = thoughtScroll.LastFocus)
        return
    thoughtScroll.LastFocus := focused
    for item in thoughtScroll.Controls {
        if (item.Control.Hwnd != focused)
            continue
        item.Control.GetPos(, , , &height)
        if (item.Top < thoughtScroll.Offset)
            SetCaptureScroll(item.Top - 8)
        else if (item.Top + height > thoughtScroll.Offset + thoughtScroll.ViewportHeight)
            SetCaptureScroll(item.Top + height - thoughtScroll.ViewportHeight + 8)
        break
    }
}

SaveThought(GuiCtrlObj, Info) {
    global thoughtGuiActive, thoughtLogsPath, thoughtWindow, thoughtForm, thoughtScroll
    
    MyGui := GuiCtrlObj.Gui
    saved := thoughtForm.Submit(false)
    
    thoughtText := saved.ThoughtText
    
    try {
        options := CaptureOptions()
        energyLevel := SelectedOption(options.Energy, saved.EnergyGroup, "Functional")
        focusLevel := SelectedOption(options.Focus, saved.FocusGroup, "It's sharp")
        activity := SelectedOption(options.Activity, saved.ActivityGroup, "Working")
        improvement := SelectedOption(options.Improvement, saved.ImprovementGroup, "Drink water")
        mood := SelectedCheckboxes(options.Mood, saved, "Mood")
        body := SelectedCheckboxes(options.Body, saved, "Body")
        headline := Trim(saved.Headline)
        thoughtEntry := "# Self Check-in Log - " . FormatTime(A_Now, "yyyy-MM-dd") . " " . FormatTime(A_Now, "HH:mm") . "`n`n"
        thoughtEntry .= "**Battery:** " . energyLevel . "`n"
        thoughtEntry .= "**Attention:** " . focusLevel . "`n"
        thoughtEntry .= "**Mood:** " . mood . "`n"
        thoughtEntry .= "**Body:** " . body . "`n"
        thoughtEntry .= "**Activity:** " . activity . "`n"
        thoughtEntry .= "**Next Two Hours:** " . improvement . "`n"
        if (headline != "")
            thoughtEntry .= "**Headline:** " . headline . "`n"
        thoughtEntry .= "`n"
        if (thoughtText != "")
            thoughtEntry .= thoughtText . "`n`n"
        WriteNote(thoughtLogsPath, thoughtEntry)
    } catch as err {
        MsgBox("Thought was not saved. Your text is still open.`n`n" . err.Message . "`n`nUse Settings to choose another notes folder if needed.", "Save failed", 48)
        return
    }
    try {
        RecordRadioUse("battery-v2", saved.EnergyGroup)
        RecordRadioUse("attention-v2", saved.FocusGroup)
        RecordRadioUse("activity", saved.ActivityGroup)
        RecordRadioUse("improvement-v2", saved.ImprovementGroup)
    } catch as err {
        TrayTip("Your note was saved, but preference counts could not be updated: " . err.Message, "Self-Check-In")
    }
    try {
        MyGui.Destroy()
        ClearCaptureHint()
        SetTimer(ClearCaptureHint, 0)
        SetTimer(KeepCaptureFocusVisible, 0)
        thoughtForm := ""
        thoughtScroll := ""
        thoughtWindow := ""
        thoughtGuiActive := false
        ScheduleNextThoughtPrompt()
        TrayTip("Check-in saved.", "Self-Check-In")
    } catch as err {
        MsgBox("Your note was saved, but the next reminder could not be scheduled.`n" . err.Message, "Self-Check-In", 48)
    }
}

SelectedOption(options, selectedIndex, fallback) {
    return (selectedIndex >= 1 && selectedIndex <= options.Length) ? options[selectedIndex] : fallback
}

GetMostUsedIndex(groupName, optionCount, initialDefault) {
    global settingsPath
    mostUsedIndex := initialDefault
    highestUseCount := 0
    Loop optionCount {
        useCount := ReadNumber("ThoughtCaptureUsage", groupName . "-" . A_Index, 0, 0, 2147483647)
        if (useCount > highestUseCount) {
            highestUseCount := useCount
            mostUsedIndex := A_Index
        }
    }
    return mostUsedIndex
}

RecordRadioUse(groupName, selectedIndex) {
    global settingsPath
    settingName := groupName . "-" . selectedIndex
    useCount := ReadNumber("ThoughtCaptureUsage", settingName, 0, 0, 2147483646)
    IniWrite(useCount + 1, settingsPath, "ThoughtCaptureUsage", settingName)
}

JoinItems(items, separator) {
    result := ""
    for index, item in items
        result .= (index > 1 ? separator : "") . item
    return result
}

DismissThought(GuiCtrlObj, Info) {
    CloseThoughtGui(GuiCtrlObj, Info)
}

CloseThoughtGui(GuiCtrlObj, Info := "") {
    global thoughtGuiActive, thoughtWindow, thoughtForm, thoughtScroll
    
    ; Handle both button click (GuiCtrlObj.Gui) and direct GUI events (GuiCtrlObj)
    if (HasProp(GuiCtrlObj, "Gui"))
        GuiCtrlObj.Gui.Destroy()
    else
        GuiCtrlObj.Destroy()
    ClearCaptureHint()
    SetTimer(ClearCaptureHint, 0)
    SetTimer(KeepCaptureFocusVisible, 0)
    thoughtForm := ""
    thoughtScroll := ""
    thoughtWindow := ""
    thoughtGuiActive := false
    ScheduleNextThoughtPrompt()
}

ReadNumber(section, key, fallback, minimum, maximum) {
    global settingsPath
    value := IniRead(settingsPath, section, key, fallback)
    return IsInteger(value) && value >= minimum && value <= maximum ? Integer(value) : fallback
}

SetupConfig(firstRun := true) {
    global thoughtLogsPath, settingsPath, startHour, endHour
    global minimumMinutes, maximumMinutes, weekends
    configFolder := EnvGet("LOCALAPPDATA") . "\Self-Check-In"
    DirCreate(configFolder)
    settingsPath := configFolder . "\settings.ini"
    legacySettings := EnvGet("LOCALAPPDATA") . "\ThoughtCapture\settings.ini"
    if (!FileExist(settingsPath) && FileExist(legacySettings))
        FileCopy(legacySettings, settingsPath, false)
    isNew := !FileExist(settingsPath)
    root := IniRead(settingsPath, "Environment", "notes-path", A_MyDocuments . "\Self-Check-In")
    if (isNew && firstRun) {
        selected := DirSelect("*" . A_MyDocuments, 3, "Choose where Self-Check-In will save your notes")
        if selected
            root := selected
    }
    loop {
        try {
            DirCreate(root . "\logs")
            probe := WriteNote(root, "Storage check")
            FileDelete(probe)
            break
        } catch as err {
            if !firstRun
                throw err
            MsgBox("Cannot save notes here.`n`n" . err.Message . "`n`nChoose another folder.", "Self-Check-In", 48)
            root := DirSelect("*" . A_MyDocuments, 3, "Choose a writable notes folder")
            if !root
                throw Error("No writable notes folder was selected.")
        }
    }
    IniWrite(root, settingsPath, "Environment", "notes-path")
    thoughtLogsPath := root . "\logs"
    startHour := ReadNumber("Schedule", "start-hour", 9, 0, 23)
    endHour := ReadNumber("Schedule", "end-hour", 17, 1, 24)
    if (endHour <= startHour) {
        startHour := 9
        endHour := 17
    }
    minimumMinutes := ReadNumber("Schedule", "minimum-minutes", 60, 1, 1440)
    maximumMinutes := ReadNumber("Schedule", "maximum-minutes", 180, minimumMinutes, 1440)
    if (maximumMinutes < minimumMinutes)
        maximumMinutes := minimumMinutes
    weekends := ReadNumber("Schedule", "weekends", 1, 0, 1)
}

SetTrayTip() {
    global paused, appVersion
    if !A_IsCompiled
        try TraySetIcon(A_ScriptDir . "\check-in.ico")
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Capture now", (*) => CaptureNow())
    A_TrayMenu.Default := "Capture now"
    A_TrayMenu.Add("Pause reminders", (*) => TogglePause())
    if paused
        A_TrayMenu.Check("Pause reminders")
    A_TrayMenu.Add("Open notes folder", (*) => OpenNotes())
    A_TrayMenu.Add("Settings", (*) => ShowSettings())
    A_TrayMenu.Add("About", (*) => MsgBox("Self-Check-In " . appVersion . "`nAndrew van der Westhuizen`nApplication license: MIT`nLocal Markdown notes. No account or telemetry.", "Self-Check-In"))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
}

CaptureNow() {
    global thoughtGuiActive
    if !thoughtGuiActive
        ShowThoughtPrompt(true)
}

TogglePause() {
    global paused, settingsPath
    nextPaused := !paused
    try IniWrite(nextPaused, settingsPath, "Schedule", "paused")
    catch as err {
        MsgBox("Could not save pause setting: " . err.Message, "Self-Check-In", 48)
        return
    }
    paused := nextPaused
    if paused
        A_TrayMenu.Check("Pause reminders")
    else
        A_TrayMenu.Uncheck("Pause reminders")
    UpdateTrayTip()
}

OpenNotes() {
    global thoughtLogsPath
    try Run('explorer.exe "' . thoughtLogsPath . '"')
    catch as err
        MsgBox(err.Message, "Cannot open notes folder", 48)
}

UpdateTrayTip() {
    global thoughtPromptScheduled, paused
    A_IconTip := "Self-Check-In" . (paused ? " (paused)" : "")
        . (ValidTimestamp(thoughtPromptScheduled) ? "`nNext: " . FormatTime(thoughtPromptScheduled, "ddd yyyy-MM-dd HH:mm") : "")
}

StartupCommand() {
    return A_IsCompiled ? '"' . A_ScriptFullPath . '"' : '"' . A_AhkPath . '" "' . A_ScriptFullPath . '"'
}

MigrateStartupRegistration(key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run") {
    legacy := RegRead(key, "ThoughtCapture", "")
    if !legacy
        return
    if !RegRead(key, "Self-Check-In", "")
        RegWrite(StartupCommand(), "REG_SZ", key, "Self-Check-In")
    RegDelete(key, "ThoughtCapture")
}

ShowSettings() {
    global settingsWindow, settingsPath, startHour, endHour, minimumMinutes, maximumMinutes, weekends
    if IsObject(settingsWindow) {
        settingsWindow.Show()
        return
    }
    window := Gui(, "Self-Check-In Settings")
    settingsWindow := window
    window.SetFont("s10", "Segoe UI")
    window.Add("Text", "w420", "Notes folder")
    window.Add("Edit", "w420 vNotesFolder", IniRead(settingsPath, "Environment", "notes-path"))
    window.Add("Button", "w100", "Browse...").OnEvent("Click", (*) => PickNotesFolder(window))
    window.Add("Text", "w420", "Active hours (0-24, same day)")
    window.Add("Edit", "w80 vStartHour Number", startHour)
    window.Add("Edit", "x+12 w80 vEndHour Number", endHour)
    window.Add("Text", "xm w420", "Random interval in minutes (minimum / maximum)")
    window.Add("Edit", "w80 vMinimumMinutes Number", minimumMinutes)
    window.Add("Edit", "x+12 w80 vMaximumMinutes Number", maximumMinutes)
    window.Add("CheckBox", "xm vWeekends Checked" . weekends, "Include weekends")
    window.Add("CheckBox", "vStartAtLogin Checked" . (RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Self-Check-In", "") = StartupCommand()), "Start at login")
    window.Add("Button", "xm w100 Default", "Save").OnEvent("Click", SaveSettings)
    window.Add("Button", "x+12 w100", "Cancel").OnEvent("Click", (*) => CloseSettings())
    window.OnEvent("Close", (*) => CloseSettings())
    window.OnEvent("Escape", (*) => CloseSettings())
    window.Show()
}

PickNotesFolder(window) {
    selected := DirSelect("*" . window["NotesFolder"].Value, 3, "Choose notes folder")
    if selected
        window["NotesFolder"].Value := selected
}

CloseSettings() {
    global settingsWindow
    settingsWindow.Destroy()
    settingsWindow := ""
}

SaveSettings(control, *) {
    global settingsPath, startHour, endHour, minimumMinutes, maximumMinutes, weekends
    global thoughtLogsPath
    window := control.Gui
    values := window.Submit(false)
    if (!IsInteger(values.StartHour) || !IsInteger(values.EndHour) || values.StartHour < 0 || values.EndHour > 24
        || values.StartHour >= values.EndHour || !IsInteger(values.MinimumMinutes) || !IsInteger(values.MaximumMinutes)
        || values.MinimumMinutes < 1 || values.MaximumMinutes > 1440 || values.MinimumMinutes > values.MaximumMinutes) {
        MsgBox("Enter valid same-day hours and an interval between 1 and 1440 minutes.", "Invalid settings", 48)
        return
    }
    root := Trim(values.NotesFolder)
    try {
        if !RegExMatch(root, "i)^(?:[a-z]:\\|\\\\)")
            throw Error("Choose an absolute notes folder path.")
        DirCreate(root . "\logs")
        probe := WriteNote(root, "Storage check")
        FileDelete(probe)
        candidate := settingsPath . ".new"
        FileCopy(settingsPath, candidate, true)
        IniWrite(root, candidate, "Environment", "notes-path")
        for key, value in Map("start-hour", values.StartHour, "end-hour", values.EndHour,
            "minimum-minutes", values.MinimumMinutes, "maximum-minutes", values.MaximumMinutes, "weekends", values.Weekends)
            IniWrite(value, candidate, "Schedule", key)
        nextDue := NextThoughtTime(A_Now, Random(Integer(values.MinimumMinutes), Integer(values.MaximumMinutes)),
            Integer(values.StartHour), Integer(values.EndHour), values.Weekends)
        IniWrite(nextDue, candidate, "Schedule", "next-due")
        if values.StartAtLogin
            RegWrite(StartupCommand(), "REG_SZ", "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Self-Check-In")
        else if RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Self-Check-In", "")
            RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Self-Check-In")
        if RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "ThoughtCapture", "")
            RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "ThoughtCapture")
        FileMove(candidate, settingsPath, true)
        SetupConfig(false)
        global thoughtPromptScheduled := nextDue
        CloseSettings()
        UpdateTrayTip()
    } catch as err {
        MsgBox("Settings could not be fully saved. Check your choices and try again.`n`n" . err.Message, "Self-Check-In", 48)
    }
}
