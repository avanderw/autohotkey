#Requires AutoHotkey v2.0

; Enhanced Notes Capture
; Quick note-taking with timer, automatic title extraction, and YAML frontmatter

MaxAutoTitleLength := 120

SetupConfig()
SetTrayTip()
TrayTip("Enhanced Notes", "Running", 1)
SetTimer(() => TrayTip(), 2000)

; Open enhanced note dialog
^Numpad4:: {
    ShowEnhancedNote()
}

ShowEnhancedNote() {
    guiId := A_TickCount
    startTime := A_TickCount
    
    MyGui := Gui()
    MyGui.Opt("+AlwaysOnTop")
    timerCtrl := MyGui.Add("Text", "x20 y15 w200", "Write time: 0s")
    MyGui.Add("Text", "x20 y40 w120", "Note type:")
    MyGui.Add("Radio", "x95 y40 vNoteTypeIdea", "Idea")
    MyGui.Add("Radio", "x165 y40 vNoteTypeWip", "WIP log")
    MyGui.Add("Edit", "x20 y65 w800 h460 vNote -Wrap", A_Clipboard)
    MyGui.Add("Button", "x600 y535 w100 h35", "Save Note").OnEvent("Click", SaveNote)
    MyGui.Add("Button", "x710 y535 w90 h35", "Cancel").OnEvent("Click", CancelNote)
    
    MyGui.Show("w820 h585")
    
    ; Create timer function and store reference
    timerFunc := () => UpdateTimer(timerCtrl, startTime)
    
    ; Add Escape key handler to close GUI
    MyGui.OnEvent("Escape", (guiObj) => guiObj.Destroy())
    
    ; Clean up timer when GUI closes
    MyGui.OnEvent("Close", (guiObj) => SetTimer(timerFunc, 0))
    
    ; Start update timer for this specific GUI
    SetTimer(timerFunc, 1000)
}

UpdateTimer(timerCtrl, startTime) {
    try {
        elapsed := Round((A_TickCount - startTime) / 1000)
        hours := Floor(elapsed / 3600)
        minutes := Floor((elapsed - hours * 3600) / 60)
        seconds := Mod(elapsed, 60)
        
        timeText := ""
        if (hours > 0)
            timeText := hours "h " minutes "m " seconds "s"
        else if (minutes > 0)
            timeText := minutes "m " seconds "s"
        else
            timeText := seconds "s"
        
        timerCtrl.Value := "Write time: " timeText
    }
}

SaveNote(GuiCtrlObj, Info) {
    MyGui := GuiCtrlObj.Gui
    saved := MyGui.Submit(false)  ; Don't hide yet, validate first
    
    note := saved.Note
    if (Trim(note) = "") {
        MsgBox("Note is empty", "Empty Note", 48)
        return
    }
    
    MyGui.Destroy()  ; Close GUI first
    noteType := ""
    if (saved.NoteTypeIdea)
        noteType := "idea"
    else if (saved.NoteTypeWip)
        noteType := "wip"

    ProcessNote(note, noteType)
}

CancelNote(GuiCtrlObj, Info) {
    GuiCtrlObj.Gui.Destroy()
}

ProcessNote(note, noteType := "") {
    global notesPath
    global MaxAutoTitleLength
    
    try {
        noteTitle := ExtractMarkdownTitle(note)
        if (noteTitle = "" || StrLen(noteTitle) > MaxAutoTitleLength) {
            noteTitle := PromptForNoteTitle()
            if (noteTitle = "")
                return
        }
        
        ; Create filename
        if (noteType = "idea")
            fileName := "idea"
        else if (noteType = "wip")
            fileName := "wip"
        else
            fileName := FormatTime(A_Now, "yyyyMMddTHHmmss")

        cleanFileTitle := BuildNoteSlug(noteTitle)
        if (cleanFileTitle = "") {
            noteTitle := PromptForNoteTitle()
            if (noteTitle = "")
                return
            cleanFileTitle := BuildNoteSlug(noteTitle)
            if (cleanFileTitle = "") {
                MsgBox("Title must contain at least one letter or number.", "Invalid Title", 48)
                return
            }
        }

        fileName .= "_" cleanFileTitle

        fileName := EnsureUniqueNoteFileName(fileName)
        noteFilePath := notesPath . "\" . fileName . ".md"
        
        ; Build YAML frontmatter
        createdDate := FormatTime(A_Now, "yyyy-MM-dd")
        createdTime := FormatTime(A_Now, "HH:mm:ss")
        
        frontMatter := "---`n"
        if (noteTitle != "") {
            cleanTitle := StrReplace(noteTitle, ":", "-")
            cleanTitle := StrReplace(cleanTitle, "`"", "'")
            cleanTitle := StrReplace(cleanTitle, ",", "-")
            cleanTitle := RegExReplace(cleanTitle, "[#\[\]{}|>]", "")
            cleanTitle := Trim(cleanTitle)
            frontMatter .= "title: " cleanTitle "`n"
        }
        frontMatter .= "created: " createdDate "T" createdTime "`n"
        frontMatter .= "---`n"
        
        finalNote := frontMatter . note
        EnsureNotesDirectory()
        FileAppend(finalNote, noteFilePath, "UTF-8")
        
        MsgBox("Note saved: " fileName ".md", "Success", 64)
    } catch as err {
        errorMessage := "Error saving note: " err.Message
        if (HasProp(err, "Extra") && err.Extra != "")
            errorMessage .= "`n`nDetails: " err.Extra
        if (IsSet(noteFilePath) && noteFilePath != "")
            errorMessage .= "`n`nPath: " noteFilePath
        MsgBox(errorMessage, "Error", 48)
    }
}

PromptForNoteTitle() {
    result := InputBox("Enter a title for this note.", "Note Title")
    if (result.Result != "OK")
        return ""

    return Trim(result.Value)
}

ExtractMarkdownTitle(note) {
    for rawLine in StrSplit(note, "`n") {
        line := Trim(rawLine, " `t`r")
        if RegExMatch(line, "^#{1,6}\s+(.+)$", &match)
            return Trim(match[1])
    }

    return ""
}

BuildNoteSlug(noteTitle) {
    cleanTitle := StrLower(noteTitle)
    cleanTitle := StrReplace(cleanTitle, " ", "-")
    cleanTitle := RegExReplace(cleanTitle, "[^a-z0-9\-_]", "")
    cleanTitle := Trim(cleanTitle, "-_")
    if (StrLen(cleanTitle) > 80)
        cleanTitle := SubStr(cleanTitle, 1, 80)
    return cleanTitle
}

EnsureUniqueNoteFileName(baseName) {
    global notesPath

    candidate := baseName
    suffix := 2
    while FileExist(notesPath . "\" . candidate . ".md") {
        candidate := baseName . "_" . suffix
        suffix += 1
    }

    return candidate
}

SetupConfig() {
    global notesPath
    
    userProfile := EnvGet("USERPROFILE")
    notesPathConfig := IniRead(A_ScriptDir . "\settings.ini", "Environment", "notes-path", "")
    
    if (notesPathConfig = "") {
        result := InputBox(, "Notes Path", "Enter the path to your notes folder")
        if (result.value = "") {
            MsgBox("Notes path not configured", "Configuration", 48)
            ExitApp()
        }
        notesPathConfig := result.value
        IniWrite(notesPathConfig, A_ScriptDir . "\settings.ini", "Environment", "notes-path")
    }
    
    notesPath := StrReplace(notesPathConfig, "~", userProfile)
    notesPath := Trim(notesPath, " `t`r`n\/")
    EnsureNotesDirectory()
}

EnsureNotesDirectory() {
    global notesPath

    if (notesPath = "")
        throw Error("Notes path is not configured.")

    if FileExist(notesPath) {
        if !InStr(FileExist(notesPath), "D")
            throw Error("Configured notes path is not a directory.",, notesPath)
        return
    }

    DirCreate(notesPath)
}

SetTrayTip() {
    try {
        A_TrayMenu.SetIcon(A_ScriptDir . "\file-text.ico", 1)
    }
    A_TrayMenu.Tip := "Enhanced Notes"
}

