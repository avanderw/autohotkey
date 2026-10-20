#Requires AutoHotkey v2.0

testFolder := A_Temp . "\Self-Check-In compiled tests " . DllCall("GetCurrentProcessId")
originalLocalAppData := EnvGet("LOCALAPPDATA")
appPid := 0
exitCode := 0
try {
    executable := A_Args[1]
    EnvSet("LOCALAPPDATA", testFolder)
    DirCreate(testFolder . "\Self-Check-In")
    config := testFolder . "\Self-Check-In\settings.ini"
    IniWrite(testFolder . "\notes", config, "Environment", "notes-path")
    IniWrite("20990101090000", config, "Schedule", "next-due")
    IniWrite(1, config, "Schedule", "paused")
    Run('"' . executable . '" --capture', , , &appPid)
    title := "Self-Check-In ahk_pid " . appPid
    captureHwnd := WinWait(title, , 10)
    if !captureHwnd
        throw Error("Compiled capture window did not open")
    title := "ahk_id " . captureHwnd
    if (IniRead(config, "Schedule", "next-due") != "20990101090000")
        throw Error("Startup replaced the persisted schedule")
    if (A_Args.Length > 1 && A_Args[2] = "--screenshots")
        CaptureWindow(captureHwnd, A_ScriptDir . "\..\dist\capture-top.png")
    panelHwnd := 0
    for controlHwnd in WinGetControlsHwnd(title) {
        if (WinGetClass(controlHwnd) = "AutoHotkeyGUI") {
            panelHwnd := controlHwnd
            break
        }
    }
    if !panelHwnd
        throw Error("Capture panel was not found")
    if (WinGetStyle(panelHwnd) & 0x200000)
        throw Error("The compact form unexpectedly needs a scrollbar on the test display")
    SendMessage(0x115, 7, 0, panelHwnd)
    if (A_Args.Length > 1 && A_Args[2] = "--screenshots")
        CaptureWindow(captureHwnd, A_ScriptDir . "\..\dist\capture-bottom.png")
    edits := []
    saveControl := 0
    for controlHwnd in WinGetControlsHwnd(title) {
        if (WinGetClass(controlHwnd) = "Edit")
            edits.Push(controlHwnd)
        if (WinGetClass(controlHwnd) = "Button" && ControlGetText(controlHwnd) = "Save Thought")
            saveControl := controlHwnd
    }
    if (edits.Length != 2)
        throw Error("Expected headline and reflection edit controls; found " . edits.Length)
    ControlGetPos(, &firstTop, , , edits[1])
    ControlGetPos(, &secondTop, , , edits[2])
    headlineControl := firstTop < secondTop ? edits[1] : edits[2]
    reflectionControl := firstTop < secondTop ? edits[2] : edits[1]
    ControlSetText("Compiled test headline", headlineControl)
    ControlSetText("Saved by the standalone executable " . Chr(0x03A9), reflectionControl)
    if (ControlGetText(reflectionControl) != "Saved by the standalone executable " . Chr(0x03A9))
        throw Error("Reflection control did not receive the test text")
    if !saveControl
        throw Error("Fixed Save button was not found")
    SendMessage(0xF5, 0, 0, saveControl)
    if !WinWaitClose(title, , 10) {
        errorText := WinExist("Save failed ahk_pid " . appPid) ? WinGetText("Save failed ahk_pid " . appPid) : "No save error dialog"
        throw Error("Compiled capture did not close after saving: " . errorText)
    }
    notes := []
    Loop Files testFolder . "\notes\logs\*.md"
        notes.Push(A_LoopFileFullPath)
    if (notes.Length != 1 || !InStr(FileRead(notes[1], "UTF-8"), "standalone executable " . Chr(0x03A9)))
        throw Error("Compiled note content was not saved correctly")
    note := FileRead(notes[1], "UTF-8")
    if (InStr(note, "# Self Check-in Log - ") != 1 || InStr(note, "Captured at"))
        throw Error("Compiled note has an incorrect title or redundant timestamp footer")
    if (!InStr(note, "**Battery:** Functional") || !InStr(note, "**Attention:** It's sharp")
        || !InStr(note, "**Mood:** None noted") || !InStr(note, "**Activity:** Working"))
        throw Error("Compiled note is missing the updated check-in fields")
    if InStr(note, "**Context:**")
        throw Error("Removed context field is still present in the compiled note")
    if (IniRead(config, "Schedule", "next-due") = "20990101090000")
        throw Error("Saving did not schedule the next prompt")
    DetectHiddenWindows(true)
    WinClose("ahk_pid " . appPid . " ahk_class AutoHotkey")
    if ProcessWaitClose(appPid, 5)
        throw Error("Compiled app did not exit cleanly")
    appPid := 0
    FileAppend("PASS: standalone full-form capture without scrolling, persisted schedule, UTF-8 save, reschedule and exit`n", "*")
} catch as err {
    FileAppend("FAIL: " . err.Message . " (line " . err.Line . ")`n", "**")
    exitCode := 1
} finally {
    if (appPid && ProcessExist(appPid))
        ProcessClose(appPid)
    EnvSet("LOCALAPPDATA", originalLocalAppData)
    if DirExist(testFolder)
        DirDelete(testFolder, true)
}
ExitApp(exitCode)

CaptureWindow(hwnd, path) {
    library := DllCall("LoadLibrary", "Str", "gdiplus.dll", "Ptr")
    if !library
        throw Error("Could not load GDI+ for the form preview")
    startup := Buffer(24, 0)
    NumPut("UInt", 1, startup)
    DllCall("gdiplus\GdiplusStartup", "Ptr*", &token := 0, "Ptr", startup, "Ptr", 0)
    rectangle := Buffer(16, 0)
    DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", rectangle)
    width := NumGet(rectangle, 8, "Int") - NumGet(rectangle, 0, "Int")
    height := NumGet(rectangle, 12, "Int") - NumGet(rectangle, 4, "Int")
    source := DllCall("GetWindowDC", "Ptr", hwnd, "Ptr")
    target := DllCall("gdi32\CreateCompatibleDC", "Ptr", source, "Ptr")
    bitmap := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", source, "Int", width, "Int", height, "Ptr")
    previous := DllCall("gdi32\SelectObject", "Ptr", target, "Ptr", bitmap, "Ptr")
    image := 0
    try {
        DllCall("dwmapi\DwmFlush")
        if !DllCall("PrintWindow", "Ptr", hwnd, "Ptr", target, "UInt", 2)
            throw Error("Could not capture the form preview")
        DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", bitmap, "Ptr", 0, "Ptr*", &image)
        encoder := Buffer(16, 0)
        DllCall("ole32\CLSIDFromString", "Str", "{557cf406-1a04-11d3-9a73-0000f81ef32e}", "Ptr", encoder)
        if DllCall("gdiplus\GdipSaveImageToFile", "Ptr", image, "Str", path, "Ptr", encoder, "Ptr", 0)
            throw Error("Could not save the form preview")
    } finally {
        if image
            DllCall("gdiplus\GdipDisposeImage", "Ptr", image)
        DllCall("gdi32\SelectObject", "Ptr", target, "Ptr", previous)
        DllCall("gdi32\DeleteObject", "Ptr", bitmap)
        DllCall("gdi32\DeleteDC", "Ptr", target)
        DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", source)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", token)
        DllCall("FreeLibrary", "Ptr", library)
    }
}