#Requires AutoHotkey v2.0

; Quick Tasks Manager
; Add tasks with optional priority and open refile folder
; Deprecated: intentionally disabled to fail silently when launched.

return

SetupConfig()
SetTrayTip()
TrayTip("Quick Tasks", "Running", 1)
SetTimer(() => TrayTip(), 2000)

; Add task via simple input box with priority parsing
^Numpad0:: {
    MyGui := Gui()
    MyGui.Add("Text", "x10 y10 w380", "Priority: (A), (B), or (C) • Date auto-added")
    taskEdit := MyGui.Add("Edit", "x10 y35 w380 h24 vTaskInput -Multi -WantReturn", "")
    MyGui.Add("Button", "x10 y70 w185 h30 Default", "Add Task").OnEvent("Click", AddTask)
    MyGui.Add("Button", "x205 y70 w185 h30", "Cancel").OnEvent("Click", CancelTask)
    MyGui.OnEvent("Escape", (guiObj) => guiObj.Destroy())
    MyGui.Title := "Add Task"
    MyGui.Show("w400 h110")
    taskEdit.Focus()
}

CancelTask(GuiCtrlObj, Info) {
    GuiCtrlObj.Gui.Destroy()
}

AddTask(GuiCtrlObj, Info) {
    MyGui := GuiCtrlObj.Gui
    MyGui.Submit()
    
    task := MyGui.Value.TaskInput
    if (task = "")
        return
    
    addedDate := FormatTime(A_Now, "yyyy-MM-dd")
    
    ; Check for priority pattern (X) at start
    if (RegExMatch(task, "^\(([A-Z])\)\s*(.*)$", &match)) {
        task := "(" match[1] ") " addedDate " " match[2]
    } else {
        task := addedDate " " task
    }
    
    try {
        FileAppend(task "`n", inbox)
        MyGui.Destroy()
        TrayTip("Quick Tasks", "Task added", 1)
        SetTimer(() => TrayTip(), 2000)
    } catch as err {
        MsgBox("Error saving task: " err.What, "Task Error", 48)
    }
}

; Open refile folder
^Numpad3:: {
    Run(refilePath)
}

SetupConfig() {
    global inbox, refilePath
    
    userProfile := EnvGet("USERPROFILE")
    inboxPath := IniRead(A_ScriptDir . "\settings.ini", "Environment", "task-inbox", "")
    
    if (inboxPath = "") {
        result := InputBox(, "Task Inbox Path", "Enter the path to your task inbox")
        if (result.value = "") {
            MsgBox("Task inbox not configured", "Configuration", 48)
            ExitApp()
        }
        inboxPath := result.value
        IniWrite(inboxPath, A_ScriptDir . "\settings.ini", "Environment", "task-inbox")
    }
    
    inbox := StrReplace(inboxPath, "~", userProfile)
    
    refilePathConfig := IniRead(A_ScriptDir . "\settings.ini", "Environment", "task-refile-path", "")
    
    if (refilePathConfig = "") {
        result := InputBox(, "Task Refile Path", "Enter the path to your task refile folder")
        if (result.value = "") {
            MsgBox("Task refile path not configured", "Configuration", 48)
            ExitApp()
        }
        refilePathConfig := result.value
        IniWrite(refilePathConfig, A_ScriptDir . "\settings.ini", "Environment", "task-refile-path")
    }
    
    refilePath := StrReplace(refilePathConfig, "~", userProfile)
}

SetTrayTip() {
    try {
        A_TrayMenu.SetIcon(A_ScriptDir . "\check-square.ico", 1)
    }
    A_TrayMenu.Tip := "Quick Tasks"
}
